import 'package:flutter/material.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../l10n/app_strings.dart';

/// Day 39 — Farmer Profile Screen
///
/// Features:
/// - Fetches farmer profile from `users/{uid}` (auto-creates default doc if missing)
/// - Avatar with farmer's initials
/// - Displays name, email, and phone number
/// - Language preference placeholder (Punjabi, Hindi, English)
/// - Logout button guarded by a confirmation dialog
/// - Comprehensive state handling: loading, error with retry, and empty/missing doc
class ProfileScreen extends StatefulWidget {
  final String? userId;
  final ProfileService? customProfileService;
  final AuthService? customAuthService;
  final Future<void> Function()? onSignOut;

  const ProfileScreen({
    super.key,
    this.userId,
    this.customProfileService,
    this.customAuthService,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileResult> _profileFuture;
  late final ProfileService _profileService;
  late final AuthService _authService;

  String _selectedLanguage = AppStrings.punjabiLanguage;

  @override
  void initState() {
    super.initState();
    _profileService = widget.customProfileService ?? ProfileService();
    _authService = widget.customAuthService ?? AuthService();
    _loadProfile();
  }

  void _loadProfile() {
    final uid = widget.userId ?? _authService.currentUserId;
    setState(() {
      _profileFuture = _profileService.getProfile(
        uid: uid,
        createIfMissing: true,
      );
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'FD';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _confirmAndLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        title: Text(
          AppStrings.logoutConfirmTitle,
          style: AppStyles.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          AppStrings.logoutConfirmMessage,
          style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.logOut),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      if (widget.onSignOut != null) {
        await widget.onSignOut!();
      } else {
        await _authService.signOut();
      }
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<ProfileResult>(
        future: _profileFuture,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: AppDimensions.spaceMedium),
                  Text(AppStrings.profileLoading, style: AppStyles.mutedStyle),
                ],
              ),
            );
          }

          // 2. Error State with Retry Button
          if (snapshot.hasError || (snapshot.hasData && !snapshot.data!.isSuccess)) {
            final errorMsg = snapshot.hasError
                ? snapshot.error.toString()
                : snapshot.data?.message ?? AppStrings.genericError;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 54, color: AppColors.caution),
                    const SizedBox(height: AppDimensions.spaceMedium),
                    Text(
                      'Unable to load profile',
                      style: AppStyles.headingStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppDimensions.spaceSmall),
                    Text(
                      errorMsg,
                      textAlign: TextAlign.center,
                      style: AppStyles.mutedStyle,
                    ),
                    const SizedBox(height: AppDimensions.spaceLarge),
                    ElevatedButton.icon(
                      onPressed: _loadProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text(AppStrings.retry),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Success State
          final UserModel? user = snapshot.data?.user;
          final String farmerName = user?.name.isNotEmpty == true ? user!.name : AppStrings.defaultFarmerName;
          final String farmerEmail = (user?.email != null && user!.email!.isNotEmpty)
              ? user.email!
              : 'Email not linked';
          final String farmerPhone = user?.phone.isNotEmpty == true ? user!.phone : 'Phone not provided';
          final String initials = _getInitials(farmerName);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimensions.spaceMedium),

                // Avatar with Initials
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppStyles.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMedium),

                // Farmer Name
                Text(
                  farmerName,
                  textAlign: TextAlign.center,
                  style: AppStyles.headingStyle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),

                // Phone Number
                Text(
                  farmerPhone,
                  textAlign: TextAlign.center,
                  style: AppStyles.mutedStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: AppDimensions.spaceLarge),

                // Profile Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.screenPaddingSmall + 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                    border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _buildProfileRow(Icons.person_outline_rounded, AppStrings.nameLabel, farmerName),
                      const Divider(height: AppDimensions.spaceMedium),
                      _buildProfileRow(Icons.email_outlined, AppStrings.emailLabel, farmerEmail),
                      const Divider(height: AppDimensions.spaceMedium),
                      _buildProfileRow(Icons.phone_outlined, AppStrings.phoneLabel, farmerPhone),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLarge),

                // Language Placeholder Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.languagePreference,
                    style: AppStyles.sectionHeadingStyle,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSmall),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                    border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: AppStrings.punjabiLanguage,
                          child: Text(AppStrings.punjabiLanguage),
                        ),
                        DropdownMenuItem(
                          value: AppStrings.hindiLanguage,
                          child: Text(AppStrings.hindiLanguage),
                        ),
                        DropdownMenuItem(
                          value: AppStrings.englishLanguage,
                          child: Text(AppStrings.englishLanguage),
                        ),
                      ],
                      onChanged: (newLang) {
                        if (newLang != null) {
                          setState(() => _selectedLanguage = newLang);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXLarge),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: _confirmAndLogout,
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                    label: Text(
                      AppStrings.logOut,
                      style: AppStyles.sectionHeadingStyle.copyWith(color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: AppDimensions.buttonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppDimensions.spaceSmall + 4),
        Text(label, style: AppStyles.mutedStyle.copyWith(fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
