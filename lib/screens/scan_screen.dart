import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _processProductCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processProductCode(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final userId = AuthService().currentUserId;

    try {
      final product = await FirestoreService().verifyProduct(code, userId: userId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            productCode: code,
            product: product,
            connectionError: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Scan screen error: $e");
      if (!mounted) return;
      // Requirement 6: Catch failure and show distinct "can't verify right now, check your connection" state
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            productCode: code,
            product: null,
            connectionError: true,
            errorMessage: "Can't verify right now, check your connection.",
          ),
        ),
      );
    }
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Enter Product Code Manually"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _manualCodeController,
                decoration: const InputDecoration(
                  labelText: "QR/Barcode Code",
                  hintText: "e.g. GENUINE-123 or FAKE-456",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text("GENUINE-123"),
                    onPressed: () {
                      _manualCodeController.text = "GENUINE-123";
                    },
                  ),
                  ActionChip(
                    label: const Text("FAKE-456"),
                    onPressed: () {
                      _manualCodeController.text = "FAKE-456";
                    },
                  ),
                  ActionChip(
                    label: const Text("ERROR-500"),
                    onPressed: () {
                      _manualCodeController.text = "ERROR-500";
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final code = _manualCodeController.text.trim();
                Navigator.pop(ctx);
                if (code.isNotEmpty) {
                  _processProductCode(code);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800),
              child: const Text("Verify Code", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product QR Code"),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: "Manual Code Entry",
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "Camera Access Required",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Or use manual entry to test QR codes in emulator/desktop environment.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showManualEntryDialog,
                        icon: const Icon(Icons.keyboard),
                        label: const Text("Enter QR Code Manually"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Verifying Product Code...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: _showManualEntryDialog,
              backgroundColor: Colors.green.shade800,
              icon: const Icon(Icons.keyboard, color: Colors.white),
              label: const Text("Enter Code Manually", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
