import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final data = _resolveProductData();
    final name = data['name'] as String? ?? 'Unknown Product';
    final batch = data['batch'] as String? ?? 'N/A';
    final manufacturer = data['manufacturer'] as String? ?? 'Unknown Manufacturer';
    final type = (data['type'] as String? ?? 'fertilizer').toLowerCase();
    final dosage = data['dosage'] as String?;

    DateTime? expiryDate;
    if (widget.product?.expiryDate != null) {
      expiryDate = widget.product!.expiryDate;
    } else if (data['expiryDate'] != null) {
      final rawExp = data['expiryDate'];
      if (rawExp is Timestamp) {
        expiryDate = rawExp.toDate();
      } else if (rawExp is DateTime) {
        expiryDate = rawExp;
      } else if (rawExp is String) {
        expiryDate = DateTime.tryParse(rawExp);
      }
    }

    final isExpired = widget.product?.isExpired ?? (expiryDate != null && DateTime.now().isAfter(expiryDate));
    final statusStr = (data['status'] as String? ?? 'active').toLowerCase();
    final isRecalled = statusStr == 'recalled';

    final isSuccess = widget.isGenuine && !widget.connectionError && !isExpired && !isRecalled;
    final primaryColor = widget.connectionError
        ? AppColors.caution
        : (isRecalled || isExpired
            ? AppColors.caution
            : (isSuccess ? AppColors.primary : AppColors.danger));

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
                              : (isSuccess ? Icons.check_circle_rounded : Icons.warning_rounded)),
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  // 2. Heading Text (~18-20px Bold)
                  Text(
                    isRecalled
                        ? "Product Recalled"
                        : (isExpired
                            ? "Product Expired"
                            : (isSuccess ? "Genuine Product" : "Not Recognized")),
                    style: AppStyles.headingStyle.copyWith(
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  // 3. Content Container / Subtext
                  if (isSuccess || isExpired || isRecalled) ...[
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
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: AppStyles.headingStyle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: AppDimensions.spaceMedium),
                          const Divider(),
                          const SizedBox(height: AppDimensions.spaceSmall + 4),
                          _buildDetailRow("Product Type", type == 'pesticide' ? "Pesticide" : "Fertilizer"),
                          const SizedBox(height: AppDimensions.spaceSmall + 2),
                          _buildDetailRow("Batch Number", batch),
                          const SizedBox(height: AppDimensions.spaceSmall + 2),
                          _buildDetailRow("Manufacturer", manufacturer),
                          if (expiryDate != null) ...[
                            const SizedBox(height: AppDimensions.spaceSmall + 2),
                            _buildDetailRow(
                              "Expiry Date",
                              DateFormat('MMM d, yyyy').format(expiryDate),
                              valueColor: isExpired ? AppColors.danger : null,
                            ),
                          ],
                          const SizedBox(height: AppDimensions.spaceSmall + 2),
                          _buildDetailRow("Product Code", widget.scannedCode),
                          if (dosage != null && dosage.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.spaceMedium),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.spaceSmall + 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: primaryColor),
                                  const SizedBox(width: AppDimensions.spaceSmall),
                                  Expanded(
                                    child: Text(
                                      dosage,
                                      style: AppStyles.bodyStyle.copyWith(fontSize: 12, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                  if (isSuccess || isExpired || isRecalled) ...[
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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
            style: AppStyles.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
