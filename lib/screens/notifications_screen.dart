import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

final notificationsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) return const Stream.empty();
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.map((d) => d.data()).toList());
    });

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _reminders = true;
  bool _priceDrops = true;
  bool _nearby = true;
  bool _payments = true;
  bool _promos = false;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(notificationsStreamProvider);
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
                child: historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (history) {
                    if (history.isEmpty) {
                      return const Center(
                        child: Text(
                          'No notifications yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, separatorIndex) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final timestamp = item['createdAt'] as Timestamp?;
                        final timeText = timestamp == null
                            ? '--'
                            : timestamp.toDate().toLocal().toString().substring(0, 16);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${item['title'] ?? 'Notification'}'),
                            subtitle: Text('${item['body'] ?? ''}'),
                            trailing: Text(
                              timeText,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        );
                      },
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
