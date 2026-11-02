import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../services/services.dart';
import '../widgets/corner_brackets_painter.dart';
import '../widgets/status_badge.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../l10n/app_strings.dart';

/// Day 34 — QR Scanner Screen connected to verifyProduct().
///
/// Features:
/// - Single-shot detection (debounced to prevent double navigation)
/// - First-QR selection when multiple barcodes appear in one frame
/// - In-place loading state overlay during verification
/// - 10-second timeout UX with "still checking..." slow connectivity message
/// - verifyProduct() call (normalization and logScan handled cleanly)
/// - Console logging of VerificationResult
/// - Temporary debug dialog with "Scan Again" & "View Result Screen" actions
/// - Lifecycle observer (pauses on inactive/paused, resumes on resumed)
/// - Permission denied explanation screen with "Open settings" button
class ScanScreen extends StatefulWidget {
  final Future<VerificationResult> Function(String code)? customVerifier;

  const ScanScreen({
    super.key,
    this.customVerifier,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  final TextEditingController _manualCodeController = TextEditingController();

  bool _isDisposed = false;
  bool _hasDetected = false;
  bool _isVerifying = false;
  bool _isSlowChecking = false;
  bool _isTorchOn = false;
  String? _currentlyVerifyingCode;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _slowTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !mounted) return;
    try {
      if (!_controller.value.hasCameraPermission) return;

      if (state == AppLifecycleState.resumed && !_hasDetected && !_isVerifying) {
        _controller.start();
      } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
        _controller.stop();
      }
    } catch (e) {
      debugPrint('[ScanScreen] Lifecycle error: $e');
    }
  }

  // =========================================================================
  // Barcode Detection & First-Code Handling
  // =========================================================================

  void _onDetect(BarcodeCapture capture) {
    // Prevent double navigation if camera fires repeatedly in quick succession
    if (_isDisposed || !mounted || _hasDetected || _isVerifying) return;

    // Filter and take the FIRST non-empty QR / barcode in the frame
    String? firstValidCode;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        firstValidCode = raw;
        break;
      }
    }

    if (firstValidCode == null) return;

    _handleCodeVerification(firstValidCode);
  }

  Future<void> _handleCodeVerification(String rawCode) async {
    if (_isDisposed || !mounted || _hasDetected || _isVerifying) return;

    setState(() {
      _hasDetected = true;
      _isVerifying = true;
      _isSlowChecking = false;
      _currentlyVerifyingCode = rawCode;
    });

    // Immediately stop camera scanner
    try {
      if (!_isDisposed) {
        await _controller.stop();
      }
    } catch (_) {}

    if (_isDisposed || !mounted) return;

    // 10-Second Timeout UX: If verification takes longer than 3.5s, notify farmer
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(milliseconds: 3500), () {
      if (!_isDisposed && mounted && _isVerifying) {
        setState(() => _isSlowChecking = true);
      }
    });

    try {
      // Call verifyProduct (normalization and logScan occur inside)
      final VerificationResult result = widget.customVerifier != null
          ? await widget.customVerifier!(rawCode)
          : await verificationService.verifyProduct(rawCode);

      _slowTimer?.cancel();

      // Print VerificationResult to console as required by Stage 6
      debugPrint('[ScanScreen Day 34] VerificationResult -> status: ${result.status.name}, code: ${result.scannedCode}, name: ${result.name ?? "N/A"}, batch: ${result.batch ?? "N/A"}, msg: ${result.message}');

      if (_isDisposed || !mounted) return;
      setState(() => _isVerifying = false);

      // Show temporary debug dialog with "Scan Again" & "View Full Result" paths
      _showVerificationDebugDialog(result);
    } catch (e) {
      _slowTimer?.cancel();
      debugPrint('[ScanScreen] Verification error: $e');

      if (_isDisposed || !mounted) return;
      setState(() => _isVerifying = false);

      final errorResult = VerificationResult.networkError(
        scannedCode: rawCode.toUpperCase(),
        message: 'Verification encountered an error: $e',
      );
      _showVerificationDebugDialog(errorResult);
    }
  }

  void _resumeScanning() {
    if (_isDisposed || !mounted) return;
    setState(() {
      _hasDetected = false;
      _isVerifying = false;
      _isSlowChecking = false;
      _currentlyVerifyingCode = null;
    });
    try {
      if (!_isDisposed) {
        _controller.start();
      }
    } catch (e) {
      debugPrint('[ScanScreen] Error resuming controller: $e');
    }
  }

  // =========================================================================
  // Temporary Debug Dialog (Stage 6)
  // =========================================================================

  void _showVerificationDebugDialog(VerificationResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          title: Row(
            children: [
              const Icon(Icons.science_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: AppDimensions.spaceSmall),
              Expanded(
                child: Text(
                  AppStrings.debugResultTitle,
                  style: AppStyles.headingStyle.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                StatusBadge(status: result.status.name),
                const SizedBox(height: AppDimensions.spaceMedium),

                // Scanned Code Display
                Text(
                  AppStrings.productCodeLabel,
                  style: AppStyles.mutedStyle.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  result.scannedCode,
                  style: AppStyles.bodyStyle.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSmall),

                // Product Name (if recognized)
                if (result.name != null) ...[
                  Text(
                    'Product Name:',
                    style: AppStyles.mutedStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.name!,
                    style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.spaceSmall),
                ],

                // Result Message
                if (result.message != null) ...[
                  Text(
                    'Message:',
                    style: AppStyles.mutedStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.message!,
                    style: AppStyles.bodyStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // "Scan Again" path
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (mounted && !_isDisposed) {
                  _resumeScanning();
                }
              },
              child: Text(
                AppStrings.scanAgain,
                style: AppStyles.bodyStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // "View Full Result" button routes to ResultScreen
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.result,
                    arguments: result,
                  );
                }
              },
              child: const Text(AppStrings.viewFullResult),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // Torch Toggle
  // =========================================================================

  Future<void> _toggleTorch() async {
    if (_isDisposed) return;
    try {
      await _controller.toggleTorch();
      if (_isDisposed || !mounted) return;
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      debugPrint('Notice: Torch unavailable on this device: $e');
    }
  }

  // =========================================================================
  // Manual Code Entry Dialog
  // =========================================================================

  void _showManualEntryDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          title: Text(
            AppStrings.manualCodeDialogTitle,
            style: AppStyles.headingStyle.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _manualCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: AppStrings.manualCodeFieldLabel,
                  hintText: AppStrings.manualCodeFieldHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMedium),
              Wrap(
                spacing: AppDimensions.spaceSmall,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text('Genuine Urea'),
                    onPressed: () => _manualCodeController.text = 'FD-FT-00101-GEN001',
                  ),
                  ActionChip(
                    label: const Text('Recalled Batch'),
                    onPressed: () => _manualCodeController.text = 'FD-PS-00202-REC002',
                  ),
                  ActionChip(
                    label: const Text('Counterfeit Alert'),
                    onPressed: () => _manualCodeController.text = 'FD-FT-99999-NOTFND',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                AppStrings.cancel,
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final code = _manualCodeController.text.trim();
                Navigator.pop(dialogCtx);
                if (code.isNotEmpty) {
                  _handleCodeVerification(code);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(AppStrings.verifyCodeBtn),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // Permission Denied View
  // =========================================================================

  Widget _buildPermissionDeniedView() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.caution.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_photography_rounded,
                  size: 40,
                  color: AppColors.caution,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLarge),
              Text(
                AppStrings.cameraPermissionRequired,
                textAlign: TextAlign.center,
                style: AppStyles.headingStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppDimensions.spaceSmall),
              Text(
                AppStrings.cameraPermissionExplanation,
                textAlign: TextAlign.center,
                style: AppStyles.bodyStyle.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXLarge),

              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                  },
                  icon: const Icon(Icons.settings_rounded, size: 20),
                  label: const Text(AppStrings.openAppSettings),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMedium),

              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.keyboard_outlined, size: 20),
                  label: const Text(AppStrings.enterCodeManually),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Main Viewfinder UI
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Feed or Permission Handler
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return _buildPermissionDeniedView();
              },
            ),
          ),

          // Top Action Overlay Bar
          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button (min 48dp touch target)
                Container(
                  width: AppDimensions.minTouchTarget,
                  height: AppDimensions.minTouchTarget,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    tooltip: 'Close scanner',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Row(
                  children: [
                    // Torch toggle button (min 48dp touch target)
                    Container(
                      width: AppDimensions.minTouchTarget,
                      height: AppDimensions.minTouchTarget,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _isTorchOn
                            ? AppColors.caution.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isTorchOn ? Colors.black : Colors.white,
                          size: 24,
                        ),
                        tooltip: _isTorchOn ? AppStrings.torchOff : AppStrings.torchOn,
                        onPressed: _toggleTorch,
                      ),
                    ),

                    // Manual code entry button (min 48dp touch target)
                    Container(
                      width: AppDimensions.minTouchTarget,
                      height: AppDimensions.minTouchTarget,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_outlined, color: Colors.white, size: 24),
                        tooltip: AppStrings.manualCodeDialogTitle,
                        onPressed: _showManualEntryDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Centered Target Viewfinder Box with 4 Corner Brackets
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: CornerBracketsPainter(
                  color: AppColors.primary,
                  strokeWidth: 4.0,
                  cornerLength: 42.0,
                  borderRadius: 14.0,
                ),
              ),
            ),
          ),

          // Instruction Text below Target Frame
          Positioned(
            bottom: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
              ),
              child: Text(
                AppStrings.pointCameraPrompt,
                textAlign: TextAlign.center,
                style: AppStyles.bodyStyle.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Verification Loading State Overlay with Timeout UX
          if (_isVerifying)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.screenPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceLarge),
                      Text(
                        AppStrings.verifyingProduct,
                        textAlign: TextAlign.center,
                        style: AppStyles.headingStyle.copyWith(color: Colors.white, fontSize: 18),
                      ),
                      if (_currentlyVerifyingCode != null) ...[
                        const SizedBox(height: AppDimensions.spaceSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                          ),
                          child: Text(
                            _currentlyVerifyingCode!,
                            style: AppStyles.mutedStyle.copyWith(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                      if (_isSlowChecking) ...[
                        const SizedBox(height: AppDimensions.spaceLarge),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.caution.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                            border: Border.all(color: AppColors.caution),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.hourglass_top_rounded, color: AppColors.caution, size: 20),
                              const SizedBox(width: AppDimensions.spaceSmall),
                              Flexible(
                                child: Text(
                                  AppStrings.stillChecking,
                                  style: AppStyles.bodyStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
