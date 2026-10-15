import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'genuine':
        bgColor = AppColors.primary.withValues(alpha: 0.12);
        textColor = AppColors.primary;
        icon = Icons.check_circle_rounded;
        label = 'GENUINE';
        break;
      case 'fake':
        bgColor = AppColors.danger.withValues(alpha: 0.12);
        textColor = AppColors.danger;
        icon = Icons.warning_amber_rounded;
        label = 'FAKE / ADULTERATED';
        break;
      default:
        bgColor = AppColors.caution.withValues(alpha: 0.15);
        textColor = AppColors.caution;
        icon = Icons.help_outline_rounded;
        label = 'UNRECOGNIZED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
        border: Border.all(color: textColor.withValues(alpha: 0.35)),
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
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
