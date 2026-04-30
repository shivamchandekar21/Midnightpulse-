import 'package:flutter/material.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sample = [
      Booking(
        title: 'Neon Pulse Fest',
        date: 'Oct 24, 2024',
        time: '9:00 PM',
        details: 'Standard Pass / Row A / Seat 12',
        status: 'PAID',
        isConfirmed: true,
        assetPath: 'assets/driveripic.png',
      ),
      Booking(
        title: 'Midnight Galaxy',
        date: 'Nov 02, 2024',
        time: '11:30 PM',
        details: 'VIP Access / All-inclusive',
        status: 'REFUNDED',
        isConfirmed: false,
        assetPath: 'assets/driveripic.png',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Booking History'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView.separated(
            itemCount: sample.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = sample[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(b.assetPath, height: 72, width: 92, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('${b.date} • ${b.time}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text(b.details, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(b.status, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: () {}, child: const Text('View')),
                      ],
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
