import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/data/models/booking_model.dart';
import 'package:midnight_pulse/providers/booking_providers.dart';
import 'package:midnight_pulse/theme/app_theme.dart';
import 'package:midnight_pulse/widgets/app_drawer.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({
    super.key,
    required this.onSelectPage,
  });

  final ValueChanged<int> onSelectPage;

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  int _selectedTab = 0;

  final List<String> tabs = ['Upcoming', 'Past Events', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final upcomingBookings = ref.watch(upcomingBookingsProvider);
    final pastBookings = ref.watch(pastBookingsProvider);
    final cancelledBookings = ref.watch(cancelledBookingsProvider);

    final activeList = switch (_selectedTab) {
      0 => upcomingBookings,
      1 => pastBookings,
      _ => cancelledBookings,
    };

    final upcomingCount = upcomingBookings.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(currentIndex: 1, onSelectPage: widget.onSelectPage),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            'My Bookings',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Digital passes, saved nights, and recent entries',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _TopIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking alerts will show up here.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Ticket vault banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.panel,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ticket vault',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.violet,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Every active pass, one swipe away.',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your upcoming nights are ready with instant entry details and seat info.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      bookingsAsync.when(
                        loading: () => const _LiveCountSkeleton(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (_) => Container(
                          height: 96,
                          width: 96,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceStrong
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                upcomingCount.toString().padLeft(2, '0'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LIVE',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tab bar
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedTab;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.16)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              tabs[index],
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Booking list
                Expanded(
                  child: bookingsAsync.when(
                    loading: () => const _BookingListSkeleton(),
                    error: (e, _) => _ErrorState(message: e.toString()),
                    data: (_) => activeList.isNotEmpty
                        ? ListView.separated(
                            itemCount: activeList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _BookingCard(
                                booking: activeList[index],
                              );
                            },
                          )
                        : const _EmptyState(),
                  ),
                ),
                const SizedBox(height: 16),

                // VIP upsell
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock VIP perks',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upgrade to Midnight Pass for priority entry, reserved lanes, and members-only drops.',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
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

// ─── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final BookingModel booking;

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return AppColors.accent;
      case BookingStatus.completed:
        return AppColors.violet;
      case BookingStatus.cancelled:
        return const Color(0xFFFF8A80);
      case BookingStatus.pending:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Event image
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: booking.imageUrl.startsWith('assets/')
                ? Image.asset(
                    booking.imageUrl.isNotEmpty
                        ? booking.imageUrl
                        : 'assets/driveripic.png',
                    height: 102,
                    width: 92,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    booking.imageUrl.isNotEmpty
                        ? booking.imageUrl
                        : '',
                    height: 102,
                    width: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/driveripic.png',
                      height: 102,
                      width: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.eventTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        booking.displayStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _BookingMeta(
                  icon: Icons.schedule_rounded,
                  text: _formatEventDate(booking.eventDate),
                ),
                const SizedBox(height: 8),
                _BookingMeta(
                  icon: Icons.location_on_outlined,
                  text: booking.eventLocation,
                ),
                const SizedBox(height: 8),
                _BookingMeta(
                  icon: Icons.confirmation_number_outlined,
                  text:
                      '${booking.ticketCount} ticket${booking.ticketCount > 1 ? 's' : ''} · ₹${booking.totalInRupees.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        booking.isUpcoming
                            ? 'View Ticket'
                            : booking.isCompleted
                                ? 'Rate Event'
                                : 'Cancelled',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, ${date.year}  ·  $hour:$minute $suffix';
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _BookingMeta extends StatelessWidget {
  const _BookingMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No tickets parked here yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Error: $message',
          style: const TextStyle(color: Color(0xFFFF8A80)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BookingListSkeleton extends StatelessWidget {
  const _BookingListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}

class _LiveCountSkeleton extends StatelessWidget {
  const _LiveCountSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      width: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

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
