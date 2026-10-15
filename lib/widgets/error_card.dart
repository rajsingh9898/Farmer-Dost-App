import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorCard({
    super.key,
    this.message = "Can't verify right now, check your connection",
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.caution.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        side: BorderSide(color: AppColors.caution.withValues(alpha: 0.4), width: 1.5),
      ),
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingSmall,
        vertical: AppDimensions.spaceSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.caution,
            ),
            const SizedBox(height: AppDimensions.spaceSmall),
            Text(
              "Connection Error",
              style: AppStyles.headingStyle.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.bodyStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceMedium),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(
                  "Retry Verification",
                  style: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.caution,
                  foregroundColor: Colors.white,
                  padding: AppDimensions.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
