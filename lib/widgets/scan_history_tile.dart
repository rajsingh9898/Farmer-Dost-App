import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Reusable tile component for displaying recent and historical product scans.
///
/// Ensures:
/// - Minimum touch target >= 48dp
/// - High outdoor sunlight contrast
/// - Scalable layout supporting >= 1.3x font size
class ScanHistoryTile extends StatelessWidget {
  final String productName;
  final String? productCode;
  final String formattedDate;
  final String status;
  final VoidCallback? onTap;
  final bool showBadge;

  const ScanHistoryTile({
    super.key,
    required this.productName,
    this.productCode,
    required this.formattedDate,
    required this.status,
    this.onTap,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isGenuine = status.toLowerCase() == 'genuine';
    final isFake = status.toLowerCase() == 'fake' ||
        status.toLowerCase() == 'counterfeit' ||
        status.toLowerCase() == 'notrecognized';

    return Container(
      constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.spaceTiny),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingSmall,
              vertical: AppDimensions.spaceSmall + 2,
            ),
            child: Row(
              children: [
                // Status icon circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isGenuine
                            ? AppColors.primary
                            : (isFake ? AppColors.danger : AppColors.caution))
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isGenuine
                          ? Icons.check_circle_rounded
                          : (isFake
                              ? Icons.cancel_rounded
                              : Icons.warning_amber_rounded),
                      color: isGenuine
                          ? AppColors.primary
                          : (isFake ? AppColors.danger : AppColors.caution),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSmall + 4),

                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        productName,
                        style: AppStyles.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              formattedDate,
                              style: AppStyles.mutedStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (productCode != null) ...[
                            Text(
                              ' • ',
                              style: AppStyles.mutedStyle,
                            ),
                            Flexible(
                              child: Text(
                                productCode!,
                                style: AppStyles.mutedStyle.copyWith(
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSmall),

                // Trailing Status Badge
                if (showBadge)
                  StatusBadge(status: status, compact: true)
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
