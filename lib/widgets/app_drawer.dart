import 'package:flutter/material.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelectPage,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectPage;

  void _showPlaceholder(BuildContext context, String label) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('$label panel is ready for your next screen.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 304,
      child: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.nightlife_rounded,
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Midnight Pulse',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bookings, tickets, and after-dark access.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const _DrawerLabel('Navigate'),
                      const SizedBox(height: 8),
                      _DrawerTile(
                        icon: Icons.home_rounded,
                        label: 'Discover',
                        selected: currentIndex == 0,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectPage(0);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.confirmation_number_rounded,
                        label: 'My Bookings',
                        selected: currentIndex == 1,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectPage(1);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        selected: currentIndex == 2,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectPage(2);
                        },
                      ),
                      const SizedBox(height: 20),
                      const _DrawerLabel('More'),
                      const SizedBox(height: 8),
                      _DrawerTile(
                        icon: Icons.bookmarks_rounded,
                        label: 'Saved Lineup',
                        onTap: () => _showPlaceholder(context, 'Saved lineup'),
                      ),
                      _DrawerTile(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Payment Methods',
                        onTap: () =>
                            _showPlaceholder(context, 'Payment methods'),
                      ),
                      _DrawerTile(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Midnight Pass',
                        onTap: () =>
                            _showPlaceholder(context, 'Midnight Pass'),
                      ),
                      _DrawerTile(
                        icon: Icons.support_agent_rounded,
                        label: 'Help & Support',
                        onTap: () =>
                            _showPlaceholder(context, 'Help and support'),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium access',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.violet,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Priority entry, instant tickets, and members-only drops.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerLabel extends StatelessWidget {
  const _DrawerLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
