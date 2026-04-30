import 'package:flutter/material.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _reminders = true;
  bool _priceDrops = true;
  bool _nearby = true;
  bool _payments = true;
  bool _promos = false;

  final _history = <Map<String, String>>[
    {'title': 'Ticket confirmed', 'message': 'Your order is confirmed', 'time': '2h'},
    {'title': 'Price drop', 'message': 'Tickets for Neon Pulse dropped', 'time': '1d'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _reminders,
                      onChanged: (v) => setState(() => _reminders = v),
                      title: const Text('Event Reminders'),
                    ),
                    SwitchListTile(
                      value: _priceDrops,
                      onChanged: (v) => setState(() => _priceDrops = v),
                      title: const Text('Price Drops'),
                    ),
                    SwitchListTile(
                      value: _nearby,
                      onChanged: (v) => setState(() => _nearby = v),
                      title: const Text('New Events Nearby'),
                    ),
                    SwitchListTile(
                      value: _payments,
                      onChanged: (v) => setState(() => _payments = v),
                      title: const Text('Payment Updates'),
                    ),
                    SwitchListTile(
                      value: _promos,
                      onChanged: (v) => setState(() => _promos = v),
                      title: const Text('Promotions / Offers'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['title']!),
                        subtitle: Text(item['message']!),
                        trailing: Text(item['time']!),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
