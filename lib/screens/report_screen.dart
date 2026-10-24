import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/report_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  final String scannedCode;

  const ReportScreen({
    super.key,
    String? scannedCode,
    String? productCode,
  }) : scannedCode = scannedCode ?? productCode ?? '';

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late TextEditingController _codeController;
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
    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled on your device.")),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission denied.")),
            );
          }
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are permanently denied.")),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        setState(() {
          _geoPoint = GeoPoint(position.latitude, position.longitude);
          _locationString = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      debugPrint("Geolocator exception: $e");
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? AuthService().currentUserId;
    final noteText = _noteController.text.trim();

    final reportPayload = ReportModel(
      productCode: widget.scannedCode,
      userId: currentUid,
      location: _locationString,
      geoPoint: _geoPoint,
      note: noteText.isNotEmpty ? noteText : null,
      status: 'pending',
    );

    try {
      await FirestoreService().submitReport(reportPayload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted, thank you"),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );

      // Return to HomeScreen
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Report Counterfeit Product"),
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
                        "Flagging fake products alerts agricultural authorities and protects fellow farmers.",
                        style: AppStyles.bodyStyle.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLarge),

              // Field 1: Read-Only Product Code
              Text(
                "Product Code",
                style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spaceSmall),
              TextFormField(
                controller: _codeController,
                readOnly: true,
                style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                "Location (Optional)",
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
                child: Row(
                  children: [
                    Icon(
                      _locationString != null ? Icons.location_on_rounded : Icons.my_location_rounded,
                      color: _locationString != null ? AppColors.danger : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.spaceSmall + 4),
                    Expanded(
                      child: Text(
                        _locationString ?? "No location captured",
                        style: AppStyles.bodyStyle.copyWith(
                          color: _locationString != null ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: _locationString != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_isFetchingLocation)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                      )
                    else
                      TextButton.icon(
                        onPressed: _fetchCurrentLocation,
                        icon: const Icon(Icons.gps_fixed, size: 16, color: AppColors.danger),
                        label: Text(
                          _locationString != null ? "Update" : "Use current location",
                          style: AppStyles.bodyStyle.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMedium + 4),

              // Field 3: Optional Multiline Note (Max 100 Chars)
              Text(
                "Note (Optional)",
                style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spaceSmall),
              TextFormField(
                controller: _noteController,
                maxLength: 100,
                maxLines: 3,
                style: AppStyles.bodyStyle,
                decoration: InputDecoration(
                  hintText: "Anything you'd like to add (optional)",
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
                          "Submit Report",
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
