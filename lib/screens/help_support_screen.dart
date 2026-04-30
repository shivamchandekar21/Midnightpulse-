import 'package:flutter/material.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      {'q': 'How do I get a refund?', 'a': 'Open the booking details and request a refund if eligible.'},
      {'q': 'How do digital tickets work?', 'a': 'You will receive a QR code that is scanned at the venue.'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final f = faqs[index];
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(f['q']!),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                          child: Text(f['a']!),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 8),
                    TextField(decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      items: const [
                        DropdownMenuItem(value: 'refund', child: Text('Refund')),
                        DropdownMenuItem(value: 'ticket', child: Text('Ticket issue')),
                        DropdownMenuItem(value: 'login', child: Text('Login problem')),
                      ],
                      onChanged: (_) {},
                      decoration: const InputDecoration(labelText: 'Issue Type'),
                    ),
                    const SizedBox(height: 8),
                    TextField(decoration: const InputDecoration(labelText: 'Message'), maxLines: 3),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(onPressed: () {}, child: const Text('Attach file')),
                        const SizedBox(width: 12),
                        ElevatedButton(onPressed: () {}, child: const Text('Submit')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
