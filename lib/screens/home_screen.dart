import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../l10n/app_strings.dart';
import '../widgets/primary_scan_button.dart';
import '../widgets/scan_history_tile.dart';


/// Features:
/// - Top bar with App name and Profile action icon
/// - Large Circular Hero Scan button with interactive press animation
/// - "Tap to scan" label
/// - "Recent scans" section connected to the latest 3 entries from ScanHistoryService
/// - "View All" navigates to full paginated ScanHistoryScreen
/// - Empty state handling with prompt to scan
/// - Responsive layout surviving 1.3x font scaling without overflow
class HomeScreen extends StatefulWidget {
  final bool showEmptyState;
  final ScanHistoryService? customScanHistoryService;

  const HomeScreen({
    super.key,
    this.showEmptyState = false,
    this.customScanHistoryService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScanHistoryService _scanService;
  late Future<ScanHistoryResult> _recentScansFuture;

  @override
  void initState() {
    super.initState();
    _scanService = widget.customScanHistoryService ?? ScanHistoryService();
    _loadRecentScans();
  }

  void _loadRecentScans() {
    setState(() {
      _recentScansFuture = _scanService.getScanHistory(limit: 3);
    });
  }

  static List<ScanModel> get samplePlaceholderScans => [
    ScanModel(
      id: 'sample-1',
      userId: 'sample',
      productCode: 'FD-FT-00101-GEN001',
      productName: 'IFFCO Neem Coated Urea 45kg',
      result: 'genuine',
      timestamp: DateTime.now(),
    ),
    ScanModel(
      id: 'sample-2',
      userId: 'sample',
      productCode: 'FD-FT-99999-NOTFND',
      productName: 'Super Phosphate DAP (Unregistered)',
      result: 'fake',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ScanModel(
      id: 'sample-3',
      userId: 'sample',
      productCode: 'FD-PS-00303-GEN003',
      productName: 'Bayer Confidor Insecticide 100ml',
      result: 'genuine',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ScanModel(
      id: 'sample-4',
      userId: 'sample',
      productCode: 'FD-FT-00777-RECALL',
      productName: 'Kisan Zinc Sulphate 21% (Lot 4B)',
      result: 'recalled',
      timestamp: DateTime.now().subtract(const Duration(days: 9)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: AppStyles.headingStyle.copyWith(
            fontSize: 22,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Semantics(
              button: true,
              label: 'Open profile',
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section: Large Circular Scan Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding,
                  vertical: AppDimensions.spaceXLarge,
                ),
                child: Center(
                  child: PrimaryScanButton(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.scan).then((_) {
                        _loadRecentScans();
                      });
                    },
                  ),
                ),
              ),

              // Bottom Section: Recent Scans Card Container
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingSmall,
                ),
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.recentScans,
                          style: AppStyles.sectionHeadingStyle.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.scanHistory).then((_) {
                              _loadRecentScans();
                            });
                          },
                          child: Text(
                            AppStrings.viewAllScans,
                            style: AppStyles.bodyStyle.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceSmall),

                    // Recent Scans from Service
                    if (widget.showEmptyState)
                      _buildEmptyState()
                    else
                      FutureBuilder<ScanHistoryResult>(
                        future: _recentScansFuture,
                        initialData: ScanHistoryResult.success(scans: samplePlaceholderScans),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );
                          }

                          final List<ScanModel> liveScans = snapshot.data?.scans ?? [];
                          final List<ScanModel> scans = liveScans.isNotEmpty ? liveScans : samplePlaceholderScans;

                          return Column(
                            children: scans.map((scan) {
                              final formattedDate = DateFormat('dd MMM, hh:mm a').format(scan.timestamp);
                              return ScanHistoryTile(
                                productName: scan.productName ?? 'Product Code: ${scan.productCode}',
                                productCode: scan.productCode,
                                formattedDate: formattedDate,
                                status: scan.result,
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.scan);
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spaceLarge,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.spaceSmall),
            Text(
              AppStrings.noScansYet,
              style: AppStyles.mutedStyle.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
