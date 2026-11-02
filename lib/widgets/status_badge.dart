import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable status badge displaying high-contrast icons and labels
/// for verification states (Genuine, Counterfeit/Fake, Recalled, Expired).
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase().trim()) {
      case 'genuine':
        bgColor = AppColors.primary.withValues(alpha: 0.12);
        borderColor = AppColors.primary.withValues(alpha: 0.4);
        textColor = AppColors.primary;
        icon = Icons.check_circle_rounded;
        label = 'GENUINE';
        break;

      case 'fake':
      case 'counterfeit':
      case 'notrecognized':
      case 'not_recognized':
        bgColor = AppColors.danger.withValues(alpha: 0.12);
        borderColor = AppColors.danger.withValues(alpha: 0.4);
        textColor = AppColors.danger;
        icon = Icons.warning_amber_rounded;
        label = 'COUNTERFEIT / FAKE';
        break;

      case 'recalled':
        bgColor = AppColors.caution.withValues(alpha: 0.15);
        borderColor = AppColors.caution.withValues(alpha: 0.5);
        textColor = AppColors.cautionText;
        icon = Icons.report_problem_rounded;
        label = 'RECALLED';
        break;

      case 'expired':
        bgColor = AppColors.caution.withValues(alpha: 0.15);
        borderColor = AppColors.caution.withValues(alpha: 0.5);
        textColor = AppColors.cautionText;
        icon = Icons.history_toggle_off_rounded;
        label = 'EXPIRED';
        break;

      default:
        bgColor = AppColors.caution.withValues(alpha: 0.12);
        borderColor = AppColors.caution.withValues(alpha: 0.4);
        textColor = AppColors.textPrimary;
        icon = Icons.help_outline_rounded;
        label = status.toUpperCase();
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: AppDimensions.spaceTiny),
            Text(
              label,
              style: AppStyles.mutedStyle.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: AppDimensions.spaceTiny + 2),
          Text(
            label,
            style: AppStyles.mutedStyle.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
