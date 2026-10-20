import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/scan_model.dart';
import '../theme/app_theme.dart';
import 'scan_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  List<ScanModel> _recentScans = [];
  bool _isLoadingScans = true;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }
  Future<void> _loadRecentScans() async {
    try {
      final userId = AuthService().currentUserId;
      final scans = await FirestoreService().getScanHistory(userId);
      if (!mounted) return;
      setState(() {
        _recentScans = scans.take(3).toList();
        _isLoadingScans = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingScans = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Farmer Dost",
          style: AppStyles.headingStyle.copyWith(fontSize: 22),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: "Logout",
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Center Hero Section — Large Circular Scan Button
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enhanced Hero Element: Concentric Touch Ring + 115px Circular Green Scan Button
                    Tooltip(
                      message: "Tap to scan product QR code",
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScanScreen()),
                          ).then((_) => _loadRecentScans());
                        },
                        borderRadius: BorderRadius.circular(70),
                        child: Container(
                          width: 135,
                          height: 135,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 115,
                            height: 115,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: AppDimensions.spaceTiny),
                          Text(
                            "Tap to scan",
                            style: AppStyles.bodyStyle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section — Recent Scans
            Container(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.cardRadius + 8)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent scans",
                        style: AppStyles.sectionHeadingStyle.copyWith(fontSize: 18),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProfileScreen()),
                          );
                        },
                        child: Text(
                          "View All",
                          style: AppStyles.bodyStyle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceSmall),
                  if (_isLoadingScans)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.screenPaddingSmall),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (_recentScans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMedium),
                      child: Center(
                        child: Text(
                          "No scans recorded yet.",
                          style: AppStyles.mutedStyle,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentScans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceSmall),
                      itemBuilder: (context, index) {
                        final scan = _recentScans[index];
                        final isGenuine = scan.result.toLowerCase() == 'genuine';
                        final formattedDate = DateFormat('MMM d, yyyy').format(scan.timestamp);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.screenPaddingSmall,
                            vertical: AppDimensions.spaceSmall + 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
                            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scan.productName ?? 'Code: ${scan.productCode}',
                                      style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: AppStyles.mutedStyle,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceSmall),
                              Icon(
                                isGenuine
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_rounded,
                                color: isGenuine
                                    ? AppColors.primary
                                    : AppColors.danger,
                                size: 22,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
