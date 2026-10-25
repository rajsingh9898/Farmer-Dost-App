import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Auth Modes: 0 = Email Login, 1 = Email Sign Up, 2 = Phone OTP
  bool _isSignUpMode = false;
  bool _isPhoneMode = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _codeSent = false;
  String _verificationId = '';
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Email Auth Actions (Login / Sign Up)
  // ---------------------------------------------------------------------------
  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both email and password.");
      return;
    }

    if (_isSignUpMode && name.isEmpty) {
      setState(() => _errorMessage = "Please enter your name.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUpMode) {
        await AuthService().signUpWithEmail(name, email, password);
      } else {
        await AuthService().signInWithEmail(email, password);
      }
      // Reactive authStateChanges will auto-route to HomeScreen
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AuthService().getFriendlyErrorMessage(e);
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP Actions
  // ---------------------------------------------------------------------------
  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = "Please enter a valid 10-digit mobile number.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await AuthService().sendOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _codeSent = true;
            _verificationId = verificationId;
          });
        }
      },
      onError: (errMsg) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = errMsg;
          });
        }
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      setState(() => _errorMessage = "Please enter the 6-digit OTP.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().verifyOtp(_verificationId, otp);
      // Reactive authStateChanges will auto-route to HomeScreen
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AuthService().getFriendlyErrorMessage(e);
        });
      }
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
              vertical: AppDimensions.spaceLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMedium),
                Text(
                  "Farmer Dost",
                  textAlign: TextAlign.center,
                  style: AppStyles.headingStyle.copyWith(fontSize: 24),
                ),
                const SizedBox(height: AppDimensions.spaceTiny),
                Text(
                  "Fertilizer & Pesticide Authenticity Verification",
                  textAlign: TextAlign.center,
                  style: AppStyles.mutedStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppDimensions.spaceLarge),

                // Method Switcher (Email vs Phone OTP)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                    border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPhoneMode = false;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isPhoneMode ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                            ),
                            child: Text(
                              "Email & Password",
                              textAlign: TextAlign.center,
                              style: AppStyles.bodyStyle.copyWith(
                                color: !_isPhoneMode ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPhoneMode = true;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isPhoneMode ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                            ),
                            child: Text(
                              "Phone OTP",
                              textAlign: TextAlign.center,
                              style: AppStyles.bodyStyle.copyWith(
                                color: _isPhoneMode ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLarge),

                // Error Message Card
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: AppDimensions.spaceSmall),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppStyles.bodyStyle.copyWith(
                              color: AppColors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),
                ],

                // -------------------------------------------------------------
                // EMAIL / PASSWORD FIELDS
                // -------------------------------------------------------------
                if (!_isPhoneMode) ...[
                  if (_isSignUpMode) ...[
                    Text("Full Name", style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppDimensions.spaceSmall),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "e.g. Harpreet Singh",
                        hintStyle: AppStyles.mutedStyle,
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMedium),
                  ],

                  Text("Email Address", style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppDimensions.spaceSmall),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "farmer@example.com",
                      hintStyle: AppStyles.mutedStyle,
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  Text("Password", style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppDimensions.spaceSmall),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Minimum 6 characters",
                      hintStyle: AppStyles.mutedStyle,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLarge),

                  // Submit Button
                  SizedBox(
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: AppDimensions.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              _isSignUpMode ? "Create Account" : "Log In",
                              style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMedium),

                  // Toggle Sign Up / Log In Mode
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUpMode = !_isSignUpMode;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUpMode
                          ? "Already have an account? Log In"
                          : "New to Farmer Dost? Create an Account",
                      style: AppStyles.bodyStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]

                // -------------------------------------------------------------
                // PHONE OTP FIELDS
                // -------------------------------------------------------------
                else ...[
                  if (!_codeSent) ...[
                    Text("Mobile Number", style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppDimensions.spaceSmall),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "9876543210",
                        hintStyle: AppStyles.mutedStyle,
                        prefixText: "+91 ",
                        prefixStyle: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLarge),
                    SizedBox(
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                "Send Verification OTP",
                                style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ] else ...[
                    Text("Enter 6-Digit OTP", style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppDimensions.spaceSmall),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: AppStyles.headingStyle.copyWith(letterSpacing: 8, fontSize: 22),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "123456",
                        hintStyle: AppStyles.mutedStyle.copyWith(letterSpacing: 4),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLarge),
                    SizedBox(
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: AppDimensions.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                "Verify & Continue",
                                style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSmall),
                    TextButton(
                      onPressed: () => setState(() => _codeSent = false),
                      child: Text(
                        "Change phone number",
                        style: AppStyles.mutedStyle.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: AppDimensions.spaceLarge),
                const Divider(),
                const SizedBox(height: AppDimensions.spaceSmall),

                // Guest / Skip Option
                Center(
                  child: TextButton.icon(
                    onPressed: _continueAsGuest,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textSecondary),
                    label: Text(
                      "Continue as Guest Farmer",
                      style: AppStyles.bodyStyle.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
