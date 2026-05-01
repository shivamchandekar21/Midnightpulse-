import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/providers/user_providers.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class SavedEventsScreen extends ConsumerWidget {
  const SavedEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedEventsAsync = ref.watch(savedEventsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Saved Events'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: savedEventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (events) => events.isEmpty
                ? const Center(child: Text('No saved events yet.'))
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final start = event.startDate;
                      final dateText =
                          '${start.day}/${start.month}/${start.year} • ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: event.imageUrl.startsWith('assets/')
                                  ? Image.asset(
                                      event.imageUrl,
                                      height: 72,
                                      width: 92,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      event.imageUrl,
                                      height: 72,
                                      width: 92,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.surfaceStrong,
                                        height: 72,
                                        width: 92,
                                        child: const Icon(
                                          Icons.image,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dateText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${event.location} • ₹${event.price}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ref
                                    .read(savedEventToggleProvider.notifier)
                                    .toggle(event.id);
                              },
                              icon: const Icon(
                                Icons.bookmark_remove_outlined,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
