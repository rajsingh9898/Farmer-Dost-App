import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/status_badge.dart';
import '../widgets/error_card.dart';
import '../widgets/custom_button.dart';
import 'report_screen.dart';
import 'scan_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final String productCode;
  final ProductModel? product;
  final bool connectionError;
  final String? errorMessage;

  const ResultScreen({
    super.key,
    required this.productCode,
    this.product,
    this.connectionError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isGenuine = product != null && product!.status.toLowerCase() == 'genuine';
    final isFakeOrUnrecognized = !connectionError && !isGenuine;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verification Result"),
        backgroundColor: connectionError
            ? Colors.amber.shade800
            : (isGenuine ? Colors.green.shade800 : Colors.red.shade800),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Requirement 6: Connection Error State
              if (connectionError) ...[
                ErrorCard(
                  message: errorMessage ?? "Can't verify right now, check your connection",
                  onRetry: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Back to Home"),
                ),
              ] else if (isGenuine) ...[
                // Genuine Result UI State
                Card(
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.green.shade300, width: 2),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 80,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "GENUINE PRODUCT",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(status: product!.status),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildDetailRow("Product Name", product!.name),
                        const SizedBox(height: 12),
                        _buildDetailRow("Batch Number", product!.batch),
                        const SizedBox(height: 12),
                        _buildDetailRow("Manufacturer", product!.manufacturer),
                        const SizedBox(height: 12),
                        _buildDetailRow("Scanned Code", productCode),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: "Scan Another Product",
                  icon: Icons.qr_code_scanner,
                  backgroundColor: Colors.green.shade800,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Back to Home"),
                ),
              ] else ...[
                // Fake or Unrecognized Result UI State
                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.red.shade300, width: 2),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 80,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product?.status == 'fake'
                              ? "WARNING: FAKE PRODUCT"
                              : "UNRECOGNIZED PRODUCT",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(status: product?.status ?? 'unrecognized'),
                        const SizedBox(height: 20),
                        Text(
                          product?.status == 'fake'
                              ? "This product code has been flagged as counterfeit or unauthorized by the manufacturer."
                              : "This product code was not found in the official genuine database. It may be fraudulent.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildDetailRow("Scanned Code", productCode),
                        if (product != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow("Product Name", product!.name),
                          const SizedBox(height: 12),
                          _buildDetailRow("Reported Vendor", product!.manufacturer),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: "Report This Product",
                  icon: Icons.report_problem,
                  backgroundColor: Colors.red.shade700,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportScreen(productCode: productCode),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: "Scan Another Product",
                  icon: Icons.qr_code_scanner,
                  backgroundColor: Colors.green.shade800,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Back to Home"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
