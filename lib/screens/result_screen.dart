import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
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

  const ResultScreen({
    super.key,
    required this.isGenuine,
    this.productData,
    required this.scannedCode,
    this.connectionError = false,
    this.errorMessage,
    this.product,
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
      if (widget.connectionError) return;
      if (widget.isGenuine) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  Map<String, dynamic> _resolveProductData() {
    if (widget.productData != null) {
      return widget.productData!;
    }
    if (widget.product != null) {
      return widget.product!.toMap();
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.isGenuine && !widget.connectionError;
    final primaryColor = widget.connectionError
        ? AppColors.caution
        : (isSuccess ? AppColors.primary : AppColors.danger);

    final data = _resolveProductData();
    final name = data['name'] as String? ?? 'Unknown Product';
    final batch = data['batch'] as String? ?? 'N/A';
    final manufacturer = data['manufacturer'] as String? ?? 'Unknown Manufacturer';

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
                if (widget.connectionError) ...[
                  // Network / Connection Offline Error State
                  ErrorCard(
                    message: widget.errorMessage ?? "Can't verify right now, check your connection",
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
                ] else ...[
                  // Shared Vertical-Centered Template Layout (Icon -> Heading -> Content/Subtext -> Action)

                  // 1. Large Circular Icon Container
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isSuccess ? AppColors.primary : AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess ? AppColors.primary : AppColors.danger).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_rounded : Icons.warning_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  // 2. Heading Text (~18-20px Bold)
                  Text(
                    isSuccess ? "Genuine Product" : "Not Recognized",
                    style: AppStyles.headingStyle.copyWith(
                      color: isSuccess ? AppColors.primary : AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  // 3. Content Container / Subtext
                  if (isSuccess) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall + 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: AppStyles.headingStyle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: AppDimensions.spaceMedium),
                          const Divider(),
                          const SizedBox(height: AppDimensions.spaceSmall + 4),
                          _buildDetailRow("Batch Number", batch),
                          const SizedBox(height: AppDimensions.spaceSmall + 2),
                          _buildDetailRow("Manufacturer", manufacturer),
                          const SizedBox(height: AppDimensions.spaceSmall + 2),
                          _buildDetailRow("Product Code", widget.scannedCode),
                        ],
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingSmall),
                      child: Text(
                        "This code was not found in our database",
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
                  if (isSuccess) ...[
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
                          "Report this product",
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.mutedStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
