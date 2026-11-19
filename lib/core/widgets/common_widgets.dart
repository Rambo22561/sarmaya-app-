import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.isDemoMode) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.warningAmber, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.demoBannerText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RiskDisclaimerCard extends StatelessWidget {
  const RiskDisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.infoBlue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.riskDisclaimer,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KpiStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const KpiStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.accentColor = AppColors.emeraldAccent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;

    if (normalized.contains('active') ||
        normalized.contains('approved') ||
        normalized.contains('paid') ||
        normalized.contains('completed') ||
        normalized == 'sold') {
      bg = AppColors.emeraldSoft;
      fg = AppColors.emeraldDark;
    } else if (normalized.contains('pending') ||
        normalized.contains('requested') ||
        normalized.contains('partial') ||
        normalized.contains('awaiting')) {
      bg = AppColors.warningSoft;
      fg = const Color(0xFFB45309);
    } else if (normalized.contains('reject') ||
        normalized.contains('fail') ||
        normalized.contains('archived') ||
        normalized.contains('suspended')) {
      bg = AppColors.dangerSoft;
      fg = AppColors.dangerRed;
    } else {
      bg = AppColors.infoSoft;
      fg = AppColors.infoBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.navyPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 40),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
