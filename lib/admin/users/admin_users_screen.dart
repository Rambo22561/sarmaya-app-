import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final referralsAsync = ref.watch(allReferralsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Member Directory & Referral Audit',
            subtitle:
                'Manage user eligibility for expense-sharing calculations and review referral relationships.',
          ),
          const SizedBox(height: 16),
          usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (users) {
              return Card(
                child: Column(
                  children: users.map((u) {
                    return SwitchListTile(
                      value: u.isEligibleMember,
                      onChanged: (val) => ref
                          .read(firebaseServiceProvider)
                          .toggleUserEligibility(
                              userId: u.uid, isEligibleMember: val),
                      title: Text('${u.fullName} (${u.role.toUpperCase()})'),
                      subtitle: Text(
                        '${u.email} • ${u.city} • Code: ${u.referralCode} • Verified: ${u.emailVerified}',
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Referral Relationships (No Cash Commission)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          referralsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (refs) {
              if (refs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No referral relationships recorded yet.'),
                  ),
                );
              }
              return Column(
                children: refs
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                  '${r.referrerName} -> ${r.referredUserName}'),
                              subtitle: Text(
                                  '${r.referredUserEmail} • Joined ${AppFormatters.date(r.createdAt)}'),
                              trailing: StatusBadge(
                                status: r.isEligibleActive
                                    ? 'eligible_active'
                                    : 'pending',
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
