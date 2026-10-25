import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/scan_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreenData {
  final UserModel? profile;
  final List<ScanModel> scans;

  ProfileScreenData({
    required this.profile,
    required this.scans,
  });
}

class ProfileScreen extends StatelessWidget {
  final String userId;

  ProfileScreen({
    super.key,
    String? userId,
  }) : userId = userId ?? AuthService().currentUserId;

  Future<ProfileScreenData> _fetchProfileAndHistory() async {
    final profile = await FirestoreService().getProfile(userId);
    final scans = await FirestoreService().getScanHistory(userId);
    return ProfileScreenData(profile: profile, scans: scans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Farmer Profile"),
      ),
      body: FutureBuilder<ProfileScreenData>(
        future: _fetchProfileAndHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 54, color: AppColors.caution),
                    const SizedBox(height: 12),
                    Text(
                      "Unable to load profile data",
                      style: AppStyles.headingStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error?.toString() ?? "Check your internet connection.",
                      textAlign: TextAlign.center,
                      style: AppStyles.mutedStyle,
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          final profile = data?.profile;
          final scans = data?.scans ?? [];

          final farmerName = profile?.name ?? 'Farmer Profile';
          final farmerPhone = profile?.phone.isNotEmpty == true ? profile!.phone : 'Phone not provided';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimensions.spaceMedium),

                // 1. Avatar Circle (Green fill, Person icon) Centered
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMedium),

                // 2. Farmer's Name (bold, ~16px) & Phone Number (muted, smaller)
                Text(
                  farmerName,
                  textAlign: TextAlign.center,
                  style: AppStyles.headingStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppDimensions.spaceTiny),
                Text(
                  farmerPhone,
                  textAlign: TextAlign.center,
                  style: AppStyles.mutedStyle,
                ),
                const SizedBox(height: AppDimensions.spaceLarge),

                // 3. Horizontal Divider
                Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.2)),
                const SizedBox(height: AppDimensions.spaceLarge),

                // 4. "Scan history" Section Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Scan history",
                    style: AppStyles.sectionHeadingStyle,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSmall + 4),

                // 5. Scrollable List of Past Scans (or Empty State)
                if (scans.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppDimensions.spaceSmall),
                        Text(
                          "No scans yet",
                          style: AppStyles.mutedStyle.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scans.length,
                    itemBuilder: (context, index) {
                      final scan = scans[index];
                      final isGenuine = scan.result.toLowerCase() == 'genuine';
                      final formattedDate = DateFormat('MMM d, yyyy').format(scan.timestamp);
                      final productName = scan.productName ?? 'Product Code: ${scan.productCode}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppDimensions.spaceSmall),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.screenPaddingSmall,
                          vertical: AppDimensions.spaceSmall + 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            // Product Name & Date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedDate,
                                    style: AppStyles.mutedStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceSmall + 4),
                            // Status Icon: Green checkmark for genuine, Red warning for fake/unrecognized
                            Icon(
                              isGenuine ? Icons.check_circle_rounded : Icons.warning_rounded,
                              color: isGenuine ? AppColors.primary : AppColors.danger,
                              size: 24,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceLarge),
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                    label: Text(
                      "Log Out",
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
                const SizedBox(height: AppDimensions.spaceMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}
