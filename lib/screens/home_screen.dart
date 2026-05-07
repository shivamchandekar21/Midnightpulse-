import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';
import 'package:midnight_pulse/providers/event_providers.dart';
import 'package:midnight_pulse/providers/user_providers.dart';
import 'package:midnight_pulse/screens/checkout_screen.dart';
import 'package:midnight_pulse/theme/app_theme.dart';
import 'package:midnight_pulse/widgets/app_drawer.dart';
import 'package:midnight_pulse/widgets/event_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onSelectPage});

  final ValueChanged<int> onSelectPage;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(eventsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _refreshEvents() {
    return ref.read(eventsControllerProvider.notifier).refreshEvents();
  }

  Future<void> _showEventActions(Event event) async {
    final action = await showModalBottomSheet<_EventAction>(
      context: context,
      backgroundColor: AppColors.surfaceStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage this event card from the live collection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _ActionTile(
                  icon: Icons.copy_all_rounded,
                  title: 'Duplicate Event',
                  subtitle: 'Create a new event document from this listing.',
                  onTap: () => Navigator.pop(context, _EventAction.duplicate),
                ),
                _ActionTile(
                  icon: event.isPremium
                      ? Icons.workspace_premium_outlined
                      : Icons.workspace_premium_rounded,
                  title: event.isPremium ? 'Remove Premium' : 'Mark as Premium',
                  subtitle: 'Update the premium status on this event.',
                  onTap: () =>
                      Navigator.pop(context, _EventAction.togglePremium),
                ),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Event',
                  subtitle: 'Remove this event from Firestore.',
                  iconColor: const Color(0xFFFF8A80),
                  onTap: () => Navigator.pop(context, _EventAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    final controller = ref.read(eventsControllerProvider.notifier);

    try {
      switch (action) {
        case _EventAction.duplicate:
          await controller.createEvent(
            event.copyWith(
              id: '',
              title: '${event.title} Copy',
              startDate: event.startDate.add(const Duration(days: 1)),
              endDate: event.endDate.add(const Duration(days: 1)),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          _showSnackBar('Event duplicated successfully.');
          break;
        case _EventAction.togglePremium:
          await controller.updateEvent(
            event.copyWith(
              isPremium: !event.isPremium,
              updatedAt: DateTime.now(),
            ),
          );
          _showSnackBar(
            event.isPremium
                ? 'Premium badge removed.'
                : 'Event marked as premium.',
          );
          break;
        case _EventAction.delete:
          await controller.deleteEvent(event.id);
          _showSnackBar('Event deleted successfully.');
          break;
      }
    } catch (error) {
      _showSnackBar(_resolveError(error));
    }
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    ref.read(eventFiltersProvider.notifier).reset();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveError(Object error) {
    if (error is AppException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _addEventToLineup(Event event) async {
    try {
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        _showSnackBar('Please log in to save events.');
        return;
      }

      final userService = ref.read(userFirestoreServiceProvider);
      await userService.saveEvent(userId, event.id);

      // Refresh saved events
      ref.invalidate(savedEventsProvider);

      _showSnackBar('Added to your lineup.');
    } catch (error) {
      _showSnackBar('Failed to save event: ${_resolveError(error)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(availableEventFiltersProvider);
    final filterState = ref.watch(eventFiltersProvider);
    final eventsAsync = ref.watch(filteredEventsStateProvider);
    final totalEvents = eventsAsync.value?.items.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(currentIndex: 0, onSelectPage: widget.onSelectPage),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: RefreshIndicator(
              onRefresh: _refreshEvents,
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                'Midnight Pulse',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Curated late-night events and instant checkout',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        _TopIconButton(
                          icon: Icons.bolt_rounded,
                          onTap: () {
                            _showSnackBar(
                              totalEvents == 0
                                  ? 'The live lineup is syncing right now.'
                                  : '$totalEvents events are ready tonight.',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppGradients.panel,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _Pill(
                                    label: 'PREMIUM BOOKINGS',
                                    color: AppColors.violet,
                                  ),
                                  const Spacer(),
                                  _Pill(
                                    label: totalEvents == 0
                                        ? 'LIVE SYNC'
                                        : '$totalEvents EVENTS',
                                    color: AppColors.accent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Book the city after dark.',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Discover new drops, lock tickets fast, and keep every pass in one place.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              const Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _FeaturePill(
                                    icon: Icons.flash_on_rounded,
                                    label: 'Instant checkout',
                                  ),
                                  _FeaturePill(
                                    icon: Icons.verified_user_rounded,
                                    label: 'Secure entry',
                                  ),
                                  _FeaturePill(
                                    icon: Icons.confirmation_number_rounded,
                                    label: 'Digital tickets',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              cursorColor: AppColors.accent,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                hintText:
                                    'Search nights, artists, or venues...',
                              ),
                              onChanged: (value) {
                                ref
                                    .read(eventFiltersProvider.notifier)
                                    .setSearchQuery(value);
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: filterState.hasActiveFilters
                                ? _clearFilters
                                : () =>
                                      _showSnackBar('Filters are ready below.'),
                            child: Icon(
                              filterState.hasActiveFilters
                                  ? Icons.close_rounded
                                  : Icons.tune_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          final selected = filter == filterState.selectedFilter;

                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(eventFiltersProvider.notifier)
                                  .selectFilter(filter);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent.withValues(alpha: 0.16)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  filter,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: selected
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
                    const SizedBox(height: 20),
                    eventsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                      error: (error, _) => _StatusState(
                        message: _resolveError(error),
                        actionLabel: 'Retry',
                        onPressed: _refreshEvents,
                      ),
                      data: (eventState) {
                        if (eventState.items.isEmpty) {
                          return _StatusState(
                            message: filterState.hasActiveFilters
                                ? 'No events match the current filters.'
                                : 'No events are live yet. Click to generate dummy events.',
                            actionLabel: filterState.hasActiveFilters
                                ? 'Clear Filters'
                                : 'Seed Dummy Events',
                            onPressed: filterState.hasActiveFilters
                                ? _clearFilters
                                : () async {
                                    final controller = ref.read(
                                      eventsControllerProvider.notifier,
                                    );
                                    await controller.createEvent(
                                      Event(
                                        id: '',
                                        title: "Neon Pulse DJ Snake",
                                        description:
                                            "The biggest neon night festival in the city. Get ready to jump!",
                                        location: "Mumbai Arena",
                                        imageUrl:
                                            "https://images.unsplash.com/photo-1540039155732-d68f7c000e30?q=80&w=2000&auto=format&fit=crop",
                                        startDate: DateTime.now().add(
                                          const Duration(days: 10),
                                        ),
                                        endDate: DateTime.now().add(
                                          const Duration(days: 10, hours: 5),
                                        ),
                                        price: 1499,
                                        tag: "EDM",
                                        isPremium: true,
                                        isActive: true,
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      ),
                                    );
                                    await controller.createEvent(
                                      Event(
                                        id: '',
                                        title: "Midnight Jazz & Blues",
                                        description:
                                            "A smooth, relaxing evening with the best Jazz musicians.",
                                        location: "The Blue Frog, Pune",
                                        imageUrl:
                                            "https://images.unsplash.com/photo-1511192336575-5a79af67a629?q=80&w=2000&auto=format&fit=crop",
                                        startDate: DateTime.now().add(
                                          const Duration(days: 5),
                                        ),
                                        endDate: DateTime.now().add(
                                          const Duration(days: 5, hours: 3),
                                        ),
                                        price: 999,
                                        tag: "Jazz",
                                        isPremium: false,
                                        isActive: true,
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      ),
                                    );
                                    await _refreshEvents();
                                  },
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 760;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount:
                                  eventState.items.length +
                                  (eventState.isLoadingMore ? 1 : 0),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isWide ? 2 : 1,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 18,
                                    childAspectRatio: isWide ? 0.88 : 0.78,
                                  ),
                              itemBuilder: (context, index) {
                                if (index >= eventState.items.length) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                    ),
                                  );
                                }

                                final event = eventState.items[index];

                                return EventCard(
                                  event: event,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CheckoutScreen(event: event),
                                      ),
                                    );
                                  },
                                  onAdd: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CheckoutScreen(event: event),
                                      ),
                                    );
                                  },
                                  onDoubleTap: () => _addEventToLineup(event),
                                  onLongPress: () => _showEventActions(event),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _EventAction { duplicate, togglePremium, delete }

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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _StatusState extends StatelessWidget {
  const _StatusState({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  onPressed();
                },
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
