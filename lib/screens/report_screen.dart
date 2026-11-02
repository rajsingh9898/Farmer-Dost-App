import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../l10n/app_strings.dart';

/// Day 38 — Counterfeit Product Report Screen
///
/// Features:
/// - Prefilled, read-only product code
/// - Optional location capture via Geolocator with 10-second timeout
/// - Non-blocking location permissions & service handling
/// - Optional note with 100-character max and live counter
/// - Double-submission prevention (submit button disabled during flight)
/// - Robust mapping of ReportResult statuses:
///   - success -> SnackBar -> return to Home
///   - alreadyReported -> SnackBar -> return to Home
///   - notSignedIn -> SnackBar prompting sign-in
///   - networkError -> keeps input and allows retry
///   - permissionDenied -> developer log & friendly message
class ReportScreen extends StatefulWidget {
  final String scannedCode;
  final ReportService? customReportService;

  const ReportScreen({
    super.key,
    String? scannedCode,
    String? productCode,
    this.customReportService,
  }) : scannedCode = scannedCode ?? productCode ?? '';

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final TextEditingController _codeController;
  final TextEditingController _noteController = TextEditingController();

  String? _locationString;
  GeoPoint? _geoPoint;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.scannedCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on your device.')),
          );
          setState(() => _isFetchingLocation = false);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
            setState(() => _isFetchingLocation = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
          setState(() => _isFetchingLocation = false);
        }
        return;
      }

      // 10-Second limit timeout for GPS coordinates acquisition
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _geoPoint = GeoPoint(position.latitude, position.longitude);
          _locationString = 'Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}';
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('[ReportScreen] Location capture notice: $e');
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final String code = _codeController.text.trim().isNotEmpty
        ? _codeController.text.trim()
        : widget.scannedCode;
    final String noteText = _noteController.text;

    try {
      final service = widget.customReportService ?? reportService;
      final ReportResult result = await service.submitReport(
        productCode: code,
        location: _geoPoint,
        note: noteText,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      switch (result.status) {
        case ReportStatus.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.reportSuccess),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
          break;

        case ReportStatus.alreadyReported:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.reportAlreadyReported),
              backgroundColor: AppColors.caution,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
          break;

        case ReportStatus.notSignedIn:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.reportNotSignedIn),
              backgroundColor: AppColors.danger,
              duration: Duration(seconds: 4),
            ),
          );
          break;

        case ReportStatus.permissionDenied:
          debugPrint('[ReportScreen] Permission denied in Firestore security rules: ${result.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.reportPermissionDenied),
              backgroundColor: AppColors.danger,
              duration: Duration(seconds: 4),
            ),
          );
          break;

        case ReportStatus.networkError:
          // Keep what the farmer typed in _noteController so they can retry
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message.isNotEmpty ? result.message : AppStrings.networkError),
              backgroundColor: AppColors.caution,
              duration: const Duration(seconds: 4),
            ),
          );
          break;

        case ReportStatus.invalidInput:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message.isNotEmpty ? result.message : AppStrings.genericError),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.reportScreenTitle),
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alert Context Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem_rounded, color: AppColors.danger, size: 32),
                    const SizedBox(width: AppDimensions.spaceSmall + 4),
                    Expanded(
                      child: Text(
                        AppStrings.reportBannerNotice,
                        style: AppStyles.bodyStyle.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLarge),

              // Field 1: Read-Only Product Code
              Text(
                AppStrings.reportCodeLabel,
                style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spaceSmall),
              TextFormField(
                controller: _codeController,
                readOnly: true,
                style: AppStyles.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.textSecondary.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMedium + 4),

              // Field 2: Optional Location Pin & Capture Row
              Text(
                AppStrings.locationLabel,
                style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spaceSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingSmall,
                  vertical: AppDimensions.spaceSmall + 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _locationString != null ? Icons.location_on_rounded : Icons.my_location_rounded,
                          color: _locationString != null ? AppColors.danger : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spaceSmall + 4),
                        Expanded(
                          child: Text(
                            _locationString ?? 'No location captured',
                            style: AppStyles.bodyStyle.copyWith(
                              color: _locationString != null ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: _locationString != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _isFetchingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                            )
                          : TextButton.icon(
                              onPressed: _fetchCurrentLocation,
                              icon: const Icon(Icons.gps_fixed, size: 16, color: AppColors.danger),
                              label: Text(
                                _locationString != null ? AppStrings.updateLocation : AppStrings.useCurrentLocation,
                                style: AppStyles.bodyStyle.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMedium + 4),

              // Field 3: Optional Multiline Note with 100 max length counter
              Text(
                AppStrings.noteLabel,
                style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spaceSmall),
              TextFormField(
                controller: _noteController,
                maxLength: 100,
                maxLines: 3,
                style: AppStyles.bodyStyle,
                decoration: InputDecoration(
                  hintText: AppStrings.noteHint,
                  hintStyle: AppStyles.mutedStyle.copyWith(fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                    borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLarge),

              // Submit Button: Full-Width Danger Red
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          AppStrings.submitReportBtn,
                          style: AppStyles.sectionHeadingStyle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.6),
                    padding: AppDimensions.buttonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
