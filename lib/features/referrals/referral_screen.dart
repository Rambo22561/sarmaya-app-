import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final referralsAsync = ref.watch(userReferralsProvider);

    final code = profile?.referralCode ?? '------';
    final shareLink = 'https://sarmayamarket.app/register?ref=$code';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Community Growth & Cost Sharing',
            subtitle:
                'More eligible paying members lower the shared monthly operating expense per member.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.policy_outlined, color: AppColors.infoBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppConstants.referralPolicyNotice,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.navyPrimary,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Unique Referral Code',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          color: AppColors.emeraldAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Copy Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Referral code copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    shareLink,
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () {
                      Share.share(
                        'Join ${AppConstants.appName} with my referral code $code to share monthly operating expenses: $shareLink',
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share Invite Link'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Referred Members',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          referralsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.group_outlined,
                  title: 'No Referred Members Yet',
                  message:
                      'Members who register with your code appear here once verified.',
                );
              }
              return Column(
                children: items
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.emeraldSoft,
                                child: Icon(Icons.person_outline,
                                    color: AppColors.emeraldDark),
                              ),
                              title: Text(r.referredUserName),
                              subtitle: Text(
                                  'Joined ${AppFormatters.date(r.createdAt)}'),
                              trailing: StatusBadge(
                                status: r.isEligibleActive
                                    ? 'eligible_active'
                                    : 'pending_eligibility',
                              ),
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
