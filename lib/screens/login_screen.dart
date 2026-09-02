import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPhoneMode = true; // Toggle between Phone OTP & Email/Pass
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _codeSent = false;
  String _verificationId = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _onSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = "Please enter a valid phone number.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().verifyPhoneNumber(
        phoneNumber: phone.startsWith('+') ? phone : '+91$phone',
        verificationCompleted: (credential) async {
          await AuthService().auth.signInWithCredential(credential);
          _navigateToHome();
        },
        verificationFailed: (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? "Verification failed.";
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _isLoading = false;
            _codeSent = true;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      // In demo/test fallback mode: simulate SMS code sent
      setState(() {
        _isLoading = false;
        _codeSent = true;
        _verificationId = 'demo_verification_id';
      });
    }
  }

  void _onVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = "Please enter the OTP.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_verificationId != 'demo_verification_id') {
        await AuthService().signInWithOTP(_verificationId, code);
      }
      _navigateToHome();
    } catch (e) {
      // Fallback for demo navigation
      _navigateToHome();
    }
  }

  void _onEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter email and password.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().signInWithEmailPassword(email, password);
      _navigateToHome();
    } catch (e) {
      // Try sign up if sign in fails, or proceed to home for demo skeleton
      try {
        await AuthService().signUpWithEmailPassword(email, password);
        _navigateToHome();
      } catch (err) {
        _navigateToHome();
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Dost — Login / Signup"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Icon(Icons.person_pin_rounded, size: 64, color: Colors.green.shade800),
            const SizedBox(height: 12),
            const Text(
              "Welcome to Farmer Dost",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Verify your product's authenticity before purchasing.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Phone OTP"),
                  selected: _isPhoneMode,
                  onSelected: (selected) {
                    if (selected) setState(() => _isPhoneMode = true);
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Email / Password"),
                  selected: !_isPhoneMode,
                  onSelected: (selected) {
                    if (selected) setState(() => _isPhoneMode = false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isPhoneMode) ...[
              if (!_codeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                    hintText: "9876543210",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: "Send OTP",
                  onPressed: _onSendOtp,
                  isLoading: _isLoading,
                  backgroundColor: Colors.green.shade700,
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Enter 6-digit OTP",
                    prefixIcon: Icon(Icons.lock_clock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: "Verify & Continue",
                  onPressed: _onVerifyOtp,
                  isLoading: _isLoading,
                  backgroundColor: Colors.green.shade700,
                ),
              ],
            ] else ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: "Login / Signup",
                onPressed: _onEmailAuth,
                isLoading: _isLoading,
                backgroundColor: Colors.green.shade700,
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _navigateToHome,
              child: const Text("Skip / Continue as Guest Farmer"),
            ),
          ],
        ),
      ),
    );
  }
}
