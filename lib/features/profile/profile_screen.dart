import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateView(message: e.toString()),
            data: (user) {
              if (user == null) {
                return const EmptyStateView(
                  icon: Icons.person_off_outlined,
                  title: 'Not Signed In',
                  message: 'Please sign in to manage your profile.',
                );
              }

              if (!_initialized) {
                _nameCtrl.text = user.fullName;
                _phoneCtrl.text = user.phone;
                _cityCtrl.text = user.city;
                _initialized = true;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DemoModeBanner(),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.navyPrimary,
                                child: Text(
                                  user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : 'M',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    Text(user.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ),
                              StatusBadge(status: user.role),
                            ],
                          ),
                          const Divider(height: 28),
                          TextField(
                            controller: _nameCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Full Name'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Mobile Number'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _cityCtrl,
                            decoration:
                                const InputDecoration(labelText: 'City'),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton(
                                onPressed: _saving
                                    ? null
                                    : () async {
                                        setState(() => _saving = true);
                                        await ref
                                            .read(firebaseServiceProvider)
                                            .updateProfile(
                                              uid: user.uid,
                                              fullName: _nameCtrl.text,
                                              phone: _phoneCtrl.text,
                                              city: _cityCtrl.text,
                                            );
                                        if (!mounted) return;
                                        setState(() => _saving = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Profile updated successfully.')));
                                      },
                                child: Text(
                                    _saving ? 'Saving...' : 'Save Changes'),
                              ),
                              if (user.isAdmin)
                                OutlinedButton.icon(
                                  onPressed: () => context.go('/admin'),
                                  icon:
                                      const Icon(Icons.admin_panel_settings),
                                  label: const Text('Open Admin Panel'),
                                ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.dangerRed,
                                ),
                                onPressed: () async {
                                  await ref
                                      .read(firebaseServiceProvider)
                                      .logout();
                                  if (!context.mounted) return;
                                  context.go('/welcome');
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text('Secure Logout'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RiskDisclaimerCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
