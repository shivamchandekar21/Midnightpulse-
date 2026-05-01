import 'package:flutter/material.dart';
import 'package:midnight_pulse/screens/admin/manage_bookings_screen.dart';
import 'package:midnight_pulse/screens/admin/manage_events_screen.dart';
import 'package:midnight_pulse/screens/admin/send_notification_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile(
            title: 'Manage Events',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageEventsScreen()),
            ),
          ),
          _Tile(
            title: 'Manage Bookings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageBookingsScreen()),
            ),
          ),
          _Tile(
            title: 'Send Notification',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SendNotificationScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
