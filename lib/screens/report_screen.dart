import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class ReportScreen extends StatefulWidget {
  final String productCode;

  const ReportScreen({super.key, required this.productCode});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late TextEditingController _codeController;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.productCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    final userId = AuthService().currentUserId;
    final report = ReportModel(
      productCode: _codeController.text.trim(),
      userId: userId,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      await FirestoreService().submitReport(report);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted successfully! Thank you for protecting farmers."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Confirmation -> back to Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.amber.shade900,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Counterfeit Product"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.report, color: Colors.red.shade700, size: 36),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Submitting a report alerts agricultural authorities and helps flag fraudulent dealers.",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Product Code (Auto-filled)",
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Store / Dealer Location (Optional)",
                hintText: "e.g. Kisan Fertilizer Shop, Ludhiana",
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Short Note / Observations (Optional)",
                hintText: "e.g. Seal was broken, price was unusually low, dilution suspected",
                prefixIcon: Icon(Icons.note_add),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: "Submit Report",
              icon: Icons.send,
              backgroundColor: Colors.red.shade800,
              isLoading: _isSubmitting,
              onPressed: _submitReport,
            ),
          ],
        ),
      ),
    );
  }
}
