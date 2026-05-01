import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/data/models/booking_model.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/data/models/payment_model.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';
import 'package:midnight_pulse/providers/booking_providers.dart';
import 'package:midnight_pulse/providers/user_providers.dart';
import 'package:midnight_pulse/screens/booking_confirmation_screen.dart';
import 'package:midnight_pulse/services/analytics_service.dart';
import 'package:midnight_pulse/services/razorpay_service.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.event,
    required this.ticketCount,
    required this.subtotal,
    required this.serviceFee,
    required this.processingFee,
    required this.totalAmount,
  });

  final Event event;
  final int ticketCount;
  final int subtotal;
  final int serviceFee;
  final int processingFee;
  final int totalAmount;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late final RazorpayService _razorpayService;
  String _selectedMethod = 'upi';
  bool _isProcessing = false;
  String? _errorMessage;
  late final AnimationController _buttonAnimController;

  static const List<_PaymentMethod> _methods = [
    _PaymentMethod(
      id: 'upi',
      title: 'UPI',
      subtitle: 'Google Pay, PhonePe, Paytm & more',
      icon: Icons.payments_rounded,
    ),
    _PaymentMethod(
      id: 'card',
      title: 'Credit / Debit Card',
      subtitle: 'Visa, Mastercard, Rupay, Amex',
      icon: Icons.credit_card_rounded,
    ),
    _PaymentMethod(
      id: 'netbanking',
      title: 'Net Banking',
      subtitle: 'All major Indian banks',
      icon: Icons.account_balance_rounded,
    ),
    _PaymentMethod(
      id: 'wallet',
      title: 'Wallet',
      subtitle: 'Paytm, PhonePe, Freecharge',
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _buttonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  Future<void> _completePayment() async {
    if (_isProcessing) return;

    final userId = ref.read(currentUserIdProvider);
    final appUser = ref.read(appUserProvider).value;
    if (userId == null) {
      setState(() {
        _errorMessage = 'Please login again to continue.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1) Create pending booking in Firestore (atomically locks seats)
      final pendingBooking = BookingModel(
        id: '',
        userId: userId,
        eventId: widget.event.id,
        eventTitle: widget.event.title,
        eventDate: widget.event.startDate,
        eventLocation: widget.event.location,
        imageUrl: widget.event.imageUrl,
        ticketCount: widget.ticketCount,
        subtotal: widget.subtotal * 100,
        serviceFee: widget.serviceFee * 100,
        processingFee: widget.processingFee * 100,
        totalAmount: widget.totalAmount * 100,
        bookingDate: DateTime.now(),
        status: BookingStatus.pending,
        paymentMethod: _selectedMethod,
      );

      final booking = await ref
          .read(createBookingProvider.notifier)
          .create(pendingBooking);

      // 2) Create Razorpay order via Cloud Function
      final order = await _razorpayService.createOrder(
        amount: booking.totalAmount,
        receipt: 'booking_${booking.id}',
        notes: {'bookingId': booking.id, 'eventId': booking.eventId},
      );

      // 3) Open Razorpay checkout (SDK handles the payment UI)
      final paymentResult = await _razorpayService.openCheckout(
        order: order,
        name: 'Midnight Pulse',
        description: widget.event.title,
        prefillEmail: appUser?.email ?? '',
        prefillContact: appUser?.phone ?? '',
      );

      // 4) Verify payment server-side via Cloud Function
      await _razorpayService.verifyPayment(
        bookingId: booking.id,
        razorpayOrderId: paymentResult.orderId,
        razorpayPaymentId: paymentResult.paymentId,
        razorpaySignature: paymentResult.signature,
      );

      // 5) Update booking status on client side
      await ref
          .read(createBookingProvider.notifier)
          .confirmPayment(
            bookingId: booking.id,
            paymentMethod: _selectedMethod,
            razorpayPaymentId: paymentResult.paymentId,
            razorpayOrderId: paymentResult.orderId,
          );

      // 6) Create a local payment record
      final payment = PaymentModel(
        id: paymentResult.paymentId,
        bookingId: booking.id,
        userId: userId,
        amount: booking.totalAmount,
        currency: 'INR',
        status: PaymentStatus.captured,
        razorpayOrderId: paymentResult.orderId,
        razorpayPaymentId: paymentResult.paymentId,
        razorpaySignature: paymentResult.signature,
        method: _selectedMethod,
        createdAt: DateTime.now(),
      );
      await ref.read(createBookingProvider.notifier).createPayment(payment);

      // 7) Build confirmed booking object for the confirmation screen
      final confirmedBooking = booking.copyWith(
        status: BookingStatus.confirmed,
        paymentMethod: _selectedMethod,
        razorpayOrderId: paymentResult.orderId,
        razorpayPaymentId: paymentResult.paymentId,
      );

      // Track analytics
      AnalyticsService.logPaymentSuccess(
        booking.totalAmount,
        _selectedMethod,
      );

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              BookingConfirmationScreen(booking: confirmedBooking),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      AnalyticsService.logPaymentFailed(errorMsg);
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose how you want to pay',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Amount card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppGradients.panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${widget.totalAmount}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.ticketCount} Ticket${widget.ticketCount > 1 ? 's' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fees Included · Instant Ticket',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Payment methods ──
                Text(
                  'Select Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: _methods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final method = _methods[index];
                      final selected = method.id == _selectedMethod;
                      return _PaymentMethodTile(
                        method: method,
                        selected: selected,
                        onTap: _isProcessing
                            ? null
                            : () =>
                                setState(() => _selectedMethod = method.id),
                      );
                    },
                  ),
                ),

                // ── Error message ──
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A80).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF8A80).withValues(alpha: 0.36),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFFF8A80), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: const Color(0xFFFF8A80)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _errorMessage = null),
                          child: const Icon(Icons.close_rounded,
                              color: Color(0xFFFF8A80), size: 18),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Security note ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Secure transaction: 256-bit SSL encrypted. Powered by Razorpay.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Pay button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _completePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor: AppColors.surfaceStrong,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Pay ₹${widget.totalAmount} with Razorpay',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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

// ─── Payment method model & tile ──────────────────────────────────────────────

class _PaymentMethod {
  const _PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.14)
                    : AppColors.surfaceStrong,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                method.icon,
                color: selected ? AppColors.accent : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: selected
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
