import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/auth/auth_service.dart';
import 'package:midnight_pulse/providers/booking_providers.dart';
import 'package:midnight_pulse/providers/user_providers.dart';
import 'package:midnight_pulse/screens/booking_history_screen.dart';
import 'package:midnight_pulse/screens/edit_profile_screen.dart';
import 'package:midnight_pulse/screens/help_support_screen.dart';
import 'package:midnight_pulse/screens/notifications_screen.dart';
import 'package:midnight_pulse/screens/admin/admin_dashboard.dart';
import 'package:midnight_pulse/screens/saved_events_screen.dart';
import 'package:midnight_pulse/theme/app_theme.dart';
import 'package:midnight_pulse/widgets/app_drawer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    required this.onSelectPage,
  });

  final ValueChanged<int> onSelectPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final upcomingCount = ref.watch(upcomingBookingsProvider).length;
    final savedCount = ref.watch(savedEventIdsProvider).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(currentIndex: 2, onSelectPage: onSelectPage),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        return _TopIconButton(
                          icon: Icons.menu_rounded,
                          onTap: () => Scaffold.of(context).openDrawer(),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your membership, stats, and preferences',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _TopIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings coming in next update.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile card — driven by real Firestore data
                userAsync.when(
                  loading: () => const _ProfileCardSkeleton(),
                  error: (e, _) => _ProfileCardError(message: e.toString()),
                  data: (user) => Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppGradients.panel,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.24),
                                blurRadius: 22,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Center(
                            child: user?.photoUrl.isNotEmpty == true
                                ? ClipOval(
                                    child: Image.network(
                                      user!.photoUrl,
                                      width: 112,
                                      height: 112,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    (user?.name.isNotEmpty == true)
                                        ? user!.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.background,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          user?.name ?? '—',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.email ?? '—',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.violet.withValues(alpha: 0.36),
                            ),
                          ),
                          child: Text(
                            user?.isMidnightPassMember == true
                                ? 'MIDNIGHT PASS MEMBER'
                                : 'FREE MEMBER',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.violet,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        label: 'Upcoming',
                        value: upcomingCount.toString().padLeft(2, '0'),
                        icon: Icons.confirmation_number_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ProfileStat(
                        label: 'Saved',
                        value: savedCount.toString().padLeft(2, '0'),
                        icon: Icons.favorite_outline_rounded,
                        color: AppColors.violet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Menu options
                _ProfileOption(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your identity, bio, and contact details.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.bookmarks_outlined,
                  title: 'Saved Events',
                  subtitle: 'Manage the nights you want to revisit later.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedEventsScreen()),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.history_rounded,
                  title: 'Booking History',
                  subtitle: 'Review past purchases and completed entries.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BookingHistoryScreen(),
                    ),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Choose alerts for drops, reminders, and payments.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'Get help with refunds, venue access, or tickets.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  ),
                ),
                userAsync.value?.isAdmin == true
                    ? _ProfileOption(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admin Panel',
                        subtitle: 'Manage events, bookings and notifications.',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboard(),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                _ProfileOption(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'End this session on the current device.',
                  onTap: () async {
                    await AuthService().signOut();
                    // AuthGate will auto-redirect to LoginPage via stream
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton & Error widgets ────────────────────────────────────────────────

class _ProfileCardSkeleton extends StatelessWidget {
  const _ProfileCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceStrong,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 140,
            height: 18,
            color: AppColors.surfaceStrong,
          ),
          const SizedBox(height: 10),
          Container(
            width: 200,
            height: 14,
            color: AppColors.surfaceStrong,
          ),
        ],
      ),
    );
  }
}

class _ProfileCardError extends StatelessWidget {
  const _ProfileCardError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Failed to load profile: $message',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFFF8A80),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDestructive ? const Color(0xFFFF8A80) : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accentColor),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDestructive ? accentColor : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}
