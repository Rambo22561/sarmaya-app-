import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(userNotificationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Notifications',
            subtitle:
                'Alerts for new projects, payment approvals, sales, profit distributions, buybacks, subscriptions, and withdrawals.',
          ),
          const SizedBox(height: 16),
          notifsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.notifications_none_outlined,
                  title: 'No Notifications',
                  message: 'You are all caught up.',
                );
              }
              return Column(
                children: items
                    .map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            color: n.isRead
                                ? AppColors.cardWhite
                                : AppColors.emeraldSoft.withValues(alpha: 0.25),
                            child: ListTile(
                              leading: Icon(
                                Icons.notifications_active_outlined,
                                color: n.isRead
                                    ? AppColors.textMuted
                                    : AppColors.emeraldDark,
                              ),
                              title: Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${n.body}\n${AppFormatters.dateTime(n.createdAt)}',
                              ),
                              isThreeLine: true,
                              onTap: () {
                                if (!n.isRead) {
                                  ref
                                      .read(firebaseServiceProvider)
                                      .markNotificationRead(n.id);
                                }
                              },
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
