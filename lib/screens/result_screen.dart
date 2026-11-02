import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/services.dart';
import '../widgets/error_card.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../l10n/app_strings.dart';

/// Days 36 & 37 — Result Screen with Real Data, Accessibility, and Dynamic Feedback
///
/// Features:
/// - Single unified template for all 6 verification outcomes:
///   1. Genuine
///   2. Recalled
///   3. Expired
///   4. Not Recognized (Counterfeit)
///   5. Network Error (Offline)
///   6. Invalid Input (Format error)
/// - Scale & Fade-in icon animation (400ms, respects reduce-motion accessibility)
/// - Haptic feedback: light impact for genuine, heavy for fake/recalled/expired, none for network error
/// - Accessible semantics tags for screen readers
/// - Strict navigation: hardware Android back goes Home (PopScope)
class ResultScreen extends StatefulWidget {
  final bool isGenuine;
  final Map<String, dynamic>? productData;
  final String scannedCode;
  final bool connectionError;
  final String? errorMessage;
  final ProductModel? product;
  final VerificationResult? verificationResult;

  const ResultScreen({
    super.key,
    this.isGenuine = false,
    this.productData,
    required this.scannedCode,
    this.connectionError = false,
    this.errorMessage,
    this.product,
    this.verificationResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  // Sound cue setting (off by default per Day 37 specification)
  bool _soundFeedbackEnabled = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bool reduceMotion = MediaQuery.of(context).disableAnimations;
        if (reduceMotion) {
          _animController.value = 1.0;
        } else {
          _animController.forward();
        }
      }
    });

    _triggerHaptics();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerHaptics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vResult = widget.verificationResult;
      final bool isNetwork = widget.connectionError || (vResult?.status == VerificationStatus.networkError);
      if (isNetwork) {
        // No haptic feedback on network error as required by Day 37
        return;
      }

      final bool isGenuineProduct = (vResult?.status == VerificationStatus.genuine) ||
          (widget.isGenuine && !widget.connectionError);

      if (isGenuineProduct) {
        HapticFeedback.lightImpact();
      } else {
        // Heavy vibration for fake, recalled, and expired
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Resolve Verification Status from VerificationResult or legacy properties
    final vResult = widget.verificationResult;

    final bool isNetworkError = (vResult?.status == VerificationStatus.networkError) || widget.connectionError;
    final bool isInvalidInput = vResult?.status == VerificationStatus.invalidInput;
    final bool isRecalled = (vResult?.status == VerificationStatus.recalled) ||
        (widget.productData?['status']?.toString().toLowerCase() == 'recalled');
    final bool isExpired = (vResult?.status == VerificationStatus.expired) ||
        (widget.product?.isExpired == true);
    final bool isNotRecognized = (vResult?.status == VerificationStatus.notRecognized) ||
        (!widget.isGenuine && !isNetworkError && !isInvalidInput && !isRecalled && !isExpired);
    final bool isGenuine = (vResult?.status == VerificationStatus.genuine) ||
        (widget.isGenuine && !isNetworkError && !isRecalled && !isExpired && !isNotRecognized && !isInvalidInput);

    // 2. Resolve Product Details
    final String productName = vResult?.name ??
        widget.product?.name ??
        (widget.productData?['name'] as String?) ??
        'Product Details';
    final String manufacturer = vResult?.manufacturer ??
        widget.product?.manufacturer ??
        (widget.productData?['manufacturer'] as String?) ??
        'N/A';
    final String batch = vResult?.batch ??
        widget.product?.batch ??
        (widget.productData?['batch'] as String?) ??
        'N/A';
    final String type = (vResult?.type ??
            widget.product?.type ??
            widget.productData?['type'] as String? ??
            'fertilizer')
        .toLowerCase();

    DateTime? expiryDate = vResult?.expiryDate ?? widget.product?.expiryDate;
    if (expiryDate == null && widget.productData?['expiryDate'] != null) {
      final raw = widget.productData!['expiryDate'];
      if (raw is Timestamp) expiryDate = raw.toDate();
      if (raw is DateTime) expiryDate = raw;
    }
    final String expiryString = expiryDate != null ? DateFormat('dd MMM yyyy').format(expiryDate) : 'N/A';

    // 3. Theme & Status Colors
    final Color primaryColor = isNetworkError
        ? AppColors.caution
        : (isRecalled || isExpired
            ? AppColors.caution
            : (isGenuine
                ? AppColors.primary
                : (isInvalidInput ? AppColors.textSecondary : AppColors.danger)));

    final String statusHeading = isNetworkError
        ? AppStrings.networkErrorHeading
        : (isInvalidInput
            ? AppStrings.invalidFormatHeading
            : (isRecalled
                ? AppStrings.recalledHeading
                : (isExpired
                    ? AppStrings.expiredHeading
                    : (isGenuine ? AppStrings.genuineHeading : AppStrings.notRecognizedHeading))));

    final String statusSubtitle = isNetworkError
        ? AppStrings.networkErrorSubtitle
        : (isInvalidInput
            ? AppStrings.invalidFormatSubtitle
            : (isRecalled
                ? AppStrings.recalledSubtitle
                : (isExpired
                    ? AppStrings.expiredSubtitle
                    : (isGenuine ? 'Verified authentic agricultural product.' : AppStrings.notRecognizedSubtitle))));

    final IconData statusIcon = isNetworkError
        ? Icons.wifi_off_rounded
        : (isInvalidInput
            ? Icons.qr_code_2_rounded
            : (isRecalled
                ? Icons.warning_amber_rounded
                : (isExpired
                    ? Icons.event_busy_rounded
                    : (isGenuine ? Icons.check_circle_rounded : Icons.gpp_bad_rounded))));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.resultTitle),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: AppStrings.backToHome,
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            },
          ),
          actions: [
            // Sound cue settings toggle (Day 37)
            IconButton(
              icon: Icon(
                _soundFeedbackEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: Colors.white,
              ),
              tooltip: AppStrings.soundFeedbackLabel,
              onPressed: () {
                setState(() => _soundFeedbackEnabled = !_soundFeedbackEnabled);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 1),
                    content: Text(
                      _soundFeedbackEnabled
                          ? 'Audio cue feedback enabled'
                          : 'Audio cue feedback muted',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
                vertical: AppDimensions.spaceLarge,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // =========================================================
                  // Status Icon with Scale & Fade-in Animation (Day 37)
                  // =========================================================
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Semantics(
                        label: 'Verification status icon: $statusHeading',
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            statusIcon,
                            size: 54,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  // =========================================================
                  // Status Heading & Subtitle
                  // =========================================================
                  Semantics(
                    header: true,
                    label: statusHeading,
                    child: Text(
                      statusHeading,
                      textAlign: TextAlign.center,
                      style: AppStyles.headingStyle.copyWith(color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceSmall),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      statusSubtitle,
                      textAlign: TextAlign.center,
                      style: AppStyles.mutedStyle.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLarge),

                  // =========================================================
                  // Body Content by Status
                  // =========================================================
                  if (isNetworkError) ...[
                    // 1. Network Error State (No Report Button!)
                    ErrorCard(
                      message: vResult?.message ??
                          widget.errorMessage ??
                          AppStrings.networkErrorSubtitle,
                      onRetry: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.scan);
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceLarge),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                        ),
                        child: const Text(AppStrings.backToHome),
                      ),
                    ),
                  ] else if (isInvalidInput) ...[
                    // 2. Invalid Input State (No Report Button!)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 28),
                          const SizedBox(height: AppDimensions.spaceSmall),
                          Text(
                            "Scanned Input: '${widget.scannedCode}'",
                            textAlign: TextAlign.center,
                            style: AppStyles.bodyStyle.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppDimensions.spaceSmall),
                          Text(
                            vResult?.message ?? "Valid format example: FD-FT-00123-A7X9KM",
                            textAlign: TextAlign.center,
                            style: AppStyles.mutedStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLarge),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.scan);
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text(AppStrings.scanAgain),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSmall + 4),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                        ),
                        child: const Text(AppStrings.backToHome),
                      ),
                    ),
                  ] else if (isGenuine || isRecalled || isExpired) ...[
                    // 3. Product Details Card (Genuine, Recalled, Expired)
                    Semantics(
                      label: 'Product details card for $productName',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall + 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  type.contains('pesticide') ? Icons.bug_report : Icons.eco,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: AppDimensions.spaceSmall),
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: AppStyles.headingStyle.copyWith(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: AppDimensions.spaceMedium),

                            _buildDetailRow(AppStrings.manufacturerLabel, manufacturer),
                            _buildDetailRow(AppStrings.batchLabel, batch),
                            _buildDetailRow(AppStrings.typeLabel, type.toUpperCase()),
                            _buildDetailRow(AppStrings.expiryDateLabel, expiryString, isHighlight: isExpired),
                            _buildDetailRow(AppStrings.productCodeLabel, widget.scannedCode),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXLarge),

                    // Actions for Genuine
                    if (isGenuine) ...[
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.scan);
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(
                            AppStrings.scanAnother,
                            style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: AppDimensions.buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSmall + 4),
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: AppDimensions.buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                            ),
                          ),
                          child: Text(
                            AppStrings.backToHome,
                            style: AppStyles.sectionHeadingStyle.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Recalled or Expired: Provide Report button
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.report, arguments: widget.scannedCode);
                          },
                          icon: const Icon(Icons.report_problem_rounded),
                          label: Text(
                            isRecalled ? AppStrings.reportRecalled : AppStrings.reportExpired,
                            style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.caution,
                            foregroundColor: Colors.white,
                            padding: AppDimensions.buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSmall + 4),
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.scan);
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(
                            AppStrings.scanAnother,
                            style: AppStyles.sectionHeadingStyle.copyWith(color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: AppDimensions.buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSmall + 4),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                        },
                        child: Text(
                          AppStrings.backToHome,
                          style: AppStyles.bodyStyle.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // 4. Not Recognized / Counterfeit Alert
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code, size: 28, color: AppColors.danger),
                          const SizedBox(height: AppDimensions.spaceSmall),
                          Text(
                            "Scanned Code: ${widget.scannedCode}",
                            style: AppStyles.bodyStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceSmall),
                          Text(
                            AppStrings.notRecognizedSubtitle,
                            textAlign: TextAlign.center,
                            style: AppStyles.mutedStyle.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXLarge),

                    // Report Fake Product Button
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.report, arguments: widget.scannedCode);
                        },
                        icon: const Icon(Icons.report_problem_rounded),
                        label: Text(
                          AppStrings.reportCounterfeit,
                          style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSmall + 4),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.scan);
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          AppStrings.scanAnother,
                          style: AppStyles.sectionHeadingStyle.copyWith(color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSmall + 4),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                      },
                      child: Text(
                        AppStrings.backToHome,
                        style: AppStyles.bodyStyle.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppStyles.mutedStyle.copyWith(fontSize: 13),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppStyles.bodyStyle.copyWith(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? AppColors.danger : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
