import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class ReportScreen extends StatefulWidget {
  final String scannedCode;

  ReportScreen({
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
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  static const Color dangerRed = Color(0xFFD32F2F);

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
          _locationString = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      debugPrint("Geolocator exception: $e");
      if (mounted) {
        // Handle gracefully: leave location empty, don't crash or block
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? AuthService().currentUserId;
    final noteText = _noteController.text.trim();

    final reportPayload = <String, dynamic>{
      'productCode': widget.scannedCode,
      'userId': currentUid,
      'location': _locationString,
      'note': noteText.isNotEmpty ? noteText : null,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirestoreService().submitReport(reportPayload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted, thank you"),
          backgroundColor: Colors.green,
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
          backgroundColor: dangerRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Report Counterfeit Product"),
        backgroundColor: dangerRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alert Context Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: dangerRed, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Flagging fake products alerts agricultural authorities and protects fellow farmers.",
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Field 1: Read-Only Product Code
              const Text(
                "Product Code",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C1E)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                readOnly: true,
                style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFEEEEEE), // Visually styled as locked/disabled
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Field 2: Optional Location Pin & Capture Row
              const Text(
                "Location (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C1E)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _locationString != null ? Icons.location_on_rounded : Icons.my_location_rounded,
                      color: _locationString != null ? dangerRed : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationString ?? "No location captured",
                        style: TextStyle(
                          fontSize: 14,
                          color: _locationString != null ? const Color(0xFF1A1C1E) : Colors.grey.shade600,
                          fontWeight: _locationString != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_isFetchingLocation)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: dangerRed),
                      )
                    else
                      TextButton.icon(
                        onPressed: _fetchCurrentLocation,
                        icon: const Icon(Icons.gps_fixed, size: 16, color: dangerRed),
                        label: Text(
                          _locationString != null ? "Update" : "Use current location",
                          style: const TextStyle(color: dangerRed, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Field 3: Optional Multiline Note (Max 100 Chars)
              const Text(
                "Note (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C1E)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLength: 100,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Anything you'd like to add (optional)",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: dangerRed, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button: Full-Width Danger Red
              SizedBox(
                width: double.infinity,
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
                      : const Text(
                          "Submit Report",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerRed,
                    disabledBackgroundColor: dangerRed.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
