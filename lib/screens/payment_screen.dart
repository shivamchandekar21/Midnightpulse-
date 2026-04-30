import 'package:flutter/material.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/screens/booking_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.event,
    required this.ticketCount,
    required this.totalAmount,
  });

  final Event event;
  final int ticketCount;
  final double totalAmount;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'UPI / Razorpay';

  final List<Map<String, String>> _methods = const [
    {
      'title': 'Pay with UPI / Razorpay',
      'subtitle': 'Instant authorization & verification',
    },
    {'title': 'Credit / Debit Card', 'subtitle': 'Visa, Mastercard, Amex'},
    {'title': 'Crypto Wallet', 'subtitle': 'BTC, ETH, SOL accepted'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF11142B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\u20B9${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fees Included | Instant Ticket',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._methods.map((method) {
              final title = method['title']!;
              final subtitle = method['subtitle']!;
              final selected = title == _selectedMethod;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethod = title),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1B1F45)
                          : const Color(0xFF11142B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF4FB8FF)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF14183A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            title.contains('UPI')
                                ? Icons.payments
                                : title.contains('Crypto')
                                    ? Icons.account_balance_wallet
                                    : Icons.credit_card,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white60
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected
                              ? const Color(0xFF4FB8FF)
                              : Colors.white30,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF11142B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Secure transaction: Your data is encrypted with 256-bit SSL protocols. Powered by Midnight Pulse Security.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingConfirmationScreen(
                        event: widget.event,
                        ticketCount: widget.ticketCount,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FB8FF),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Complete Purchase',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
