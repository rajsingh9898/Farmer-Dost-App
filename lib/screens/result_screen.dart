import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/services.dart';
import '../widgets/error_card.dart';
import '../theme/app_theme.dart';
import 'report_screen.dart';
import 'scan_screen.dart';
import 'home_screen.dart';

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

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _triggerHaptics();
  }

  void _triggerHaptics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.connectionError || (widget.verificationResult?.status == VerificationStatus.networkError)) {
        return;
      }
      final isSuccess = (widget.verificationResult?.status == VerificationStatus.genuine) ||
          (widget.isGenuine && !widget.connectionError);
      if (isSuccess) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Resolve State from VerificationResult if present, else fallback to legacy props
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
        (widget.isGenuine && !isNetworkError && !isRecalled && !isExpired);

    // Resolve Product Details
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

    // Color Theme Determination
    final Color primaryColor = isNetworkError
        ? AppColors.caution
        : (isRecalled || isExpired
            ? AppColors.caution
            : (isGenuine
                ? AppColors.primary
                : (isInvalidInput ? AppColors.caution : AppColors.danger)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Verification Result"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
                if (isNetworkError) ...[
                  // Network / Connection Error State
                  ErrorCard(
                    message: vResult?.message ??
                        widget.errorMessage ??
                        "Can't verify right now, check your cellular connection.",
                    onRetry: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spaceLarge),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: AppDimensions.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                        ),
                      ),
                      child: const Text("Back to Home"),
                    ),
                  ),
                ] else if (isInvalidInput) ...[
                  // Invalid Format State
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.caution,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.caution.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),
                  Text(
                    "Invalid Code Format",
                    style: AppStyles.headingStyle.copyWith(color: AppColors.caution),
                  ),
                  const SizedBox(height: AppDimensions.spaceSmall),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      vResult?.message ??
                          "The scanned code '${widget.scannedCode}' does not match the Farmer Dost code format. Valid example: FD-FT-00123-A7X9KM.",
                      textAlign: TextAlign.center,
                      style: AppStyles.mutedStyle,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLarge),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanScreen()),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan Again"),
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
                ] else ...[
                  // 1. Status Icon Container
                  Container(
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
                      isRecalled
                          ? Icons.warning_amber_rounded
                          : (isExpired
                              ? Icons.event_busy_rounded
                              : (isGenuine ? Icons.check_circle_rounded : Icons.gpp_bad_rounded)),
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  // 2. Heading Text
                  Text(
                    isRecalled
                        ? "Product Recalled"
                        : (isExpired
                            ? "Product Expired"
                            : (isGenuine
                                ? "Genuine Product"
                                : (isNotRecognized ? "Not Recognized / Fake" : "Unverified Product"))),
                    style: AppStyles.headingStyle.copyWith(color: primaryColor),
                  ),
                  const SizedBox(height: AppDimensions.spaceSmall),

                  // Optional message / alert banner
                  if (vResult?.message != null && !isGenuine) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMedium),
                      padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        vResult!.message!,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyStyle.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  // 3. Product Details Card (Genuine, Recalled, Expired)
                  if (isGenuine || isExpired || isRecalled) ...[
                    Container(
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
                          // Product Name
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

                          // Metadata Fields
                          _buildDetailRow("Manufacturer", manufacturer),
                          _buildDetailRow("Batch Number", batch),
                          _buildDetailRow("Product Type", type.toUpperCase()),
                          _buildDetailRow("Expiry Date", expiryString, isHighlight: isExpired),
                          _buildDetailRow("Product Code", widget.scannedCode),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Not Recognized Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingSmall),
                      child: Text(
                        "This product code was not found in the official registry. Possible counterfeit product.",
                        textAlign: TextAlign.center,
                        style: AppStyles.mutedStyle.copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMedium),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code, size: 20, color: AppColors.danger),
                          const SizedBox(width: AppDimensions.spaceSmall),
                          Text(
                            "Scanned Code: ${widget.scannedCode}",
                            style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spaceXLarge),

                  // 4. Action Buttons
                  if (isGenuine) ...[
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const ScanScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          "Scan Another",
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
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                        ),
                        child: Text(
                          "Done",
                          style: AppStyles.sectionHeadingStyle.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Not genuine / Recalled / Expired -> Provide Report Button
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(scannedCode: widget.scannedCode),
                            ),
                          );
                        },
                        icon: const Icon(Icons.report_problem_rounded),
                        label: Text(
                          isRecalled
                              ? "Report Recalled Product"
                              : (isExpired ? "Report Expired Product" : "Report Counterfeit Product"),
                          style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRecalled || isExpired ? AppColors.caution : AppColors.danger,
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const ScanScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          "Scan Another",
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
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        "Back to Home",
                        style: AppStyles.bodyStyle.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
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
    );
  }
}
