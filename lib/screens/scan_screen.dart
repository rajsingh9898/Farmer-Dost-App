import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/corner_brackets_painter.dart';
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
  bool _isTorchOn = false;
  bool _showLowLightHint = false;

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

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
      _showLowLightHint = false;
    });
    _controller.toggleTorch();
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
                    onPressed: () => _manualCodeController.text = "GENUINE-123",
                  ),
                  ActionChip(
                    label: const Text("FAKE-456"),
                    onPressed: () => _manualCodeController.text = "FAKE-456",
                  ),
                  ActionChip(
                    label: const Text("ERROR-500"),
                    onPressed: () => _manualCodeController.text = "ERROR-500",
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Viewfinder Live Camera Feed Fill
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Container(
                  color: const Color(0xFF1A1C1E),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            "Camera Viewfinder Active",
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tap below to test QR codes in emulator/desktop environment.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _showManualEntryDialog,
                            icon: const Icon(Icons.keyboard),
                            label: const Text("Enter Code Manually"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Transparent Top Overlay Bar
          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close / Back X Icon
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  tooltip: "Exit Scanner",
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    if (_showLowLightHint) ...[
                      GestureDetector(
                        onTap: _toggleTorch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            "Tap for light",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? Colors.yellow : Colors.white,
                        size: 26,
                      ),
                      tooltip: "Toggle Torch",
                      onPressed: _toggleTorch,
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard, color: Colors.white, size: 26),
                      tooltip: "Manual Entry",
                      onPressed: _showManualEntryDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Centered 200x200 Square Target Frame (4 Corner Brackets)
          Center(
            child: SizedBox(
              width: 210,
              height: 210,
              child: CustomPaint(
                painter: CornerBracketsPainter(
                  color: _isProcessing
                      ? const Color(0xFF00E676) // Bright Neon Green in detecting state
                      : const Color(0xFF2E7D32), // Standard Agriculture Green
                  strokeWidth: 4.0,
                  cornerLength: 40.0,
                  borderRadius: 14.0,
                ),
              ),
            ),
          ),

          // Single Line Instruction Text
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Point camera at the QR code",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showLowLightHint = !_showLowLightHint);
                  },
                  icon: const Icon(Icons.brightness_medium, color: Colors.white60, size: 16),
                  label: Text(
                    _showLowLightHint ? "Hide low-light hint" : "Simulate low-light state",
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Processing Indicator Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E676)),
                    SizedBox(height: 16),
                    Text(
                      "Verifying Product Code...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
