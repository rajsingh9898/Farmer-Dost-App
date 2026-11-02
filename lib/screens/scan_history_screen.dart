import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/services.dart';
import '../widgets/scan_history_tile.dart';
import '../widgets/status_badge.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../l10n/app_strings.dart';

/// Day 40 — Paginated Scan History Screen
///
/// Features:
/// - Paginated list (20 scans per page) ordered newest first
/// - Pull-to-refresh
/// - "Load More" pagination trigger
/// - Empty state ("No scans yet" with direct Scan button)
/// - Read-only detail sheet on row tap
/// - Handles loading, error with retry, and full offline gracefully
class ScanHistoryScreen extends StatefulWidget {
  final ScanHistoryService? customScanHistoryService;

  const ScanHistoryScreen({
    super.key,
    this.customScanHistoryService,
  });

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  late final ScanHistoryService _scanService;

  final List<ScanModel> _scans = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scanService = widget.customScanHistoryService ?? ScanHistoryService();
    _fetchInitialScans();
  }

  Future<void> _fetchInitialScans() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    final ScanHistoryResult result = await _scanService.getScanHistory(limit: 20);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _scans.clear();
        _scans.addAll(result.scans);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoadingInitial = false;
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? AppStrings.genericError;
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _loadMoreScans() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final ScanHistoryResult result = await _scanService.getScanHistory(
      limit: 20,
      startAfter: _lastDocument,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _scans.addAll(result.scans);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } else {
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? AppStrings.networkError),
          backgroundColor: AppColors.caution,
        ),
      );
    }
  }

  void _showScanDetails(ScanModel scan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.cardRadius)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Details',
                  style: AppStyles.headingStyle.copyWith(fontSize: 18),
                ),
                StatusBadge(status: scan.result),
              ],
            ),
            const Divider(height: AppDimensions.spaceLarge),
            _buildDetailField('Product Name', scan.productName ?? 'Unspecified Name'),
            _buildDetailField('Product Code', scan.productCode),
            _buildDetailField(
              'Scanned Date',
              DateFormat('dd MMMM yyyy, hh:mm a').format(scan.timestamp),
            ),
            if (scan.id != null && scan.id!.isNotEmpty) _buildDetailField('Audit Reference', scan.id!),
            const SizedBox(height: AppDimensions.spaceMedium),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(AppStrings.done),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.mutedStyle.copyWith(fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppStyles.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.scanHistoryTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 54, color: AppColors.caution),
              const SizedBox(height: AppDimensions.spaceMedium),
              Text(
                'Unable to load scan history',
                style: AppStyles.headingStyle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppDimensions.spaceSmall),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppStyles.mutedStyle,
              ),
              const SizedBox(height: AppDimensions.spaceLarge),
              ElevatedButton.icon(
                onPressed: _fetchInitialScans,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    if (_scans.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchInitialScans,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.spaceMedium),
            Text(
              AppStrings.noScansYet,
              textAlign: TextAlign.center,
              style: AppStyles.headingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppDimensions.spaceSmall),
            Text(
              'Verify fertilizer & pesticide authenticity by scanning their QR codes.',
              textAlign: TextAlign.center,
              style: AppStyles.mutedStyle,
            ),
            const SizedBox(height: AppDimensions.spaceLarge),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(AppStrings.tapToScan),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInitialScans,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        itemCount: _scans.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _scans.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMedium),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : OutlinedButton(
                        onPressed: _loadMoreScans,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        child: const Text(AppStrings.loadMore),
                      ),
              ),
            );
          }

          final scan = _scans[index];
          final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(scan.timestamp);

          return ScanHistoryTile(
            productName: scan.productName ?? 'Product Code: ${scan.productCode}',
            productCode: scan.productCode,
            formattedDate: formattedDate,
            status: scan.result,
            showBadge: true,
            onTap: () => _showScanDetails(scan),
          );
        },
      ),
    );
  }
}
