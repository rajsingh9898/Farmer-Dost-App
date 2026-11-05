/// Centralized UI Strings for Farmer Dost App.
///
/// Consolidating all customer-facing text enables seamless localization
/// into Punjabi (ਪੰਜਾਬੀ), Hindi (हिन्दी), and English in upcoming phases.
class AppStrings {
  AppStrings._();
  // App & Common
  static const String appName = 'Farmer Dost';
  static const String appTagline = 'Scan. Verify. Trust.';
  static const String cancel = 'Cancel';
  static const String done = 'Done';
  static const String ok = 'OK';
  static const String retry = 'Try Again';
  static const String backToHome = 'Back to Home';
  static const String loading = 'Loading...';
  static const String networkError = 'Network offline. Please check your connection.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String splashInitFailed = 'Unable to connect to service. Please check your internet connection and try again.';
  static const String splashCheckingAuth = 'Connecting to secure service...';
  static const String splashRetry = 'Retry Connection';

  // Authentication & Profile
  static const String loginTitle = 'Welcome Kisan Dost';
  static const String loginSubtitle = 'Sign in to verify agricultural inputs & protect your harvest.';
  static const String signUpTitle = 'Create Farmer Account';
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'e.g. kisan@punjab.in';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Minimum 6 characters';
  static const String nameLabel = 'Full Name';
  static const String nameHint = 'e.g. Gurpreet Singh';
  static const String phoneLabel = 'Phone Number';
  static const String phoneHint = 'e.g. +91 98765 43210';
  static const String districtLabel = 'District';
  static const String districtHint = 'e.g. Ludhiana, Amritsar';
  static const String signIn = 'Sign In';
  static const String signUp = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String logOut = 'Log Out';
  static const String logoutConfirmTitle = 'Log Out?';
  static const String logoutConfirmMessage = 'Are you sure you want to log out of Farmer Dost?';
  static const String emailRequired = 'Please enter your email address.';
  static const String emailInvalid = 'Please enter a valid email address.';
  static const String passwordRequired = 'Please enter your password.';
  static const String passwordTooShort = 'Password must be at least 6 characters.';
  static const String nameRequired = 'Please enter your full name.';
  static const String passwordResetDialogTitle = 'Reset Password';
  static const String passwordResetDialogMessage = 'Enter your registered email address to receive a password reset link.';
  static const String sendResetLink = 'Send Reset Link';
  static const String passwordResetSuccess = 'Password reset email sent! Please check your inbox.';
  static const String switchToSignUp = "Don't have an account? Sign Up";
  static const String switchToLogin = 'Already have an account? Sign In';
  static const String emailTab = 'Email & Password';
  static const String phoneTab = 'Phone OTP';
  static const String continueAsGuest = 'Continue as Guest';



  // Home Screen
  static const String tapToScan = 'Tap to Scan Product';
  static const String scanHeroSubtitle = 'Point camera at QR code on fertilizer or pesticide bag';
  static const String enterCodeManually = 'Enter Code Manually';
  static const String recentScans = 'Recent Scans';
  static const String viewAllScans = 'View All';
  static const String noScansYet = 'No scans recorded yet.';

  // Scanner Screen
  static const String scannerTitle = 'Scan Product Code';
  static const String pointCameraPrompt = 'Point camera at the QR code';
  static const String torchOn = 'Torch On';
  static const String torchOff = 'Torch Off';
  static const String manualCodeDialogTitle = 'Enter Product Code Manually';
  static const String manualCodeFieldLabel = 'QR / Product Code';
  static const String manualCodeFieldHint = 'e.g. FD-FT-00101-GEN001';
  static const String verifyCodeBtn = 'Verify Code';
  static const String cameraPermissionRequired = 'Camera Permission Required';
  static const String cameraPermissionExplanation = 'Farmer Dost requires camera access to scan fertilizer and pesticide authenticity QR codes.';
  static const String openAppSettings = 'Open App Settings';
  static const String scannedQrTitle = 'Scanned QR Code';
  static const String scanAgain = 'Scan Again';
  static const String verifyingProduct = 'Verifying Product Code...';
  static const String stillChecking = 'Still checking... Poor connectivity detected.';
  static const String debugResultTitle = 'Verification Result';
  static const String viewFullResult = 'View Full Result';

  // Verification Results
  static const String resultTitle = 'Verification Result';
  static const String genuineHeading = 'Genuine Product';
  static const String recalledHeading = 'Product Recalled';
  static const String expiredHeading = 'Product Expired';
  static const String notRecognizedHeading = 'Not Recognized / Counterfeit Alert';
  static const String invalidFormatHeading = 'Invalid Code Format';
  static const String networkErrorHeading = 'Verification Offline';
  static const String manufacturerLabel = 'Manufacturer';
  static const String batchLabel = 'Batch Number';
  static const String typeLabel = 'Product Type';
  static const String expiryDateLabel = 'Expiry Date';
  static const String productCodeLabel = 'Product Code';
  static const String scanAnother = 'Scan Another';
  static const String reportCounterfeit = 'Report Counterfeit Product';
  static const String reportRecalled = 'Report Recalled Product';
  static const String reportExpired = 'Report Expired Product';

  // Counterfeit Reporting
  static const String reportScreenTitle = 'Report Counterfeit Product';
  static const String reportBannerNotice = 'Flagging fake products alerts agricultural authorities and protects fellow farmers.';
  static const String reportCodeLabel = 'Reported Product Code';
  static const String locationLabel = 'Location (Optional)';
  static const String locationCaptured = 'Location Captured';
  static const String useCurrentLocation = 'Use current location';
  static const String updateLocation = 'Update location';
  static const String noteLabel = 'Note (Optional)';
  static const String noteHint = 'Describe packaging, seller mandi, or chemical suspicion (max 100 characters)';
  static const String submitReportBtn = 'Submit Report';
  static const String reportSuccess = 'Report submitted successfully! Thank you for protecting Punjab farmers.';
  static const String reportAlreadyReported = 'You have already reported this product code. Your report is pending review.';
  static const String reportNotSignedIn = 'Please sign in to submit a counterfeit report.';
  static const String reportPermissionDenied = 'Report permission denied by server security policy.';

  // Result Subtitles & Accessibility
  static const String recalledSubtitle = 'Recalled, do not use.';
  static const String expiredSubtitle = 'Expired.';
  static const String notRecognizedSubtitle = 'This code was not found in our database.';
  static const String networkErrorSubtitle = "Can't verify right now, check your cellular connection.";
  static const String invalidFormatSubtitle = "This doesn't look like a Farmer Dost code.";
  static const String soundFeedbackLabel = 'Audio Cue Feedback';

  // Profile Screen
  static const String profileTitle = 'Farmer Profile';
  static const String profileLoading = 'Loading profile details...';
  static const String editProfile = 'Edit Profile';
  static const String languagePreference = 'Language Preference';
  static const String punjabiLanguage = 'ਪੰਜਾਬੀ (Punjabi)';
  static const String hindiLanguage = 'हिन्दी (Hindi)';
  static const String englishLanguage = 'English';
  static const String defaultFarmerName = 'Kisan Dost';

  // Scan History Screen
  static const String scanHistoryTitle = 'Scan History';
  static const String loadMore = 'Load More';
  static const String allScansLoaded = 'All recent scans loaded';
}
