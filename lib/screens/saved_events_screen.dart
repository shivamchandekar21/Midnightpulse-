import 'package:flutter/material.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class SavedEventsScreen extends StatelessWidget {
  const SavedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = List.generate(
      6,
      (i) => {
        'title': 'Saved Event ${i + 1}',
        'when': 'Oct ${10 + i}, 2024 • 11:00 PM',
        'where': 'Venue ${i + 1}',
        'price': '₹${499 + i * 100}',
      },
    );

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
          child: ListView.separated(
            itemCount: sample.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = sample[index];

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
                      child: Container(
                        color: AppColors.surfaceStrong,
                        height: 72,
                        width: 92,
                        child: const Icon(Icons.image, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(item['when']!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text('${item['where']} • ${item['price']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from saved (local preview)')));
                      },
                      icon: const Icon(Icons.bookmark_remove_outlined, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
