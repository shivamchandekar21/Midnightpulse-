import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/screens/payment_screen.dart';
import 'package:midnight_pulse/services/analytics_service.dart';
import 'package:midnight_pulse/theme/app_theme.dart';
import 'package:midnight_pulse/widgets/event_image.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  int ticketCount = 1;
  late final AnimationController _ticketAnimController;
  late Animation<double> _ticketScale;

  int get subtotal => widget.event.price * ticketCount;
  int get serviceFee => (subtotal * 0.055).round();
  int get processingFee => (subtotal * 0.018).round();
  int get total => subtotal + serviceFee + processingFee;

  int get _availableSeats {
    if (widget.event.totalSeats <= 0) return 999; // unlimited
    return (widget.event.totalSeats - widget.event.bookedSeats).clamp(0, 9999);
  }

  bool get _isSoldOut => widget.event.totalSeats > 0 && _availableSeats <= 0;

  @override
  void initState() {
    super.initState();
    _ticketAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _ticketScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ticketAnimController, curve: Curves.easeOut),
    );
    AnalyticsService.logBookingStarted(widget.event.id);
  }

  @override
  void dispose() {
    _ticketAnimController.dispose();
    super.dispose();
  }

  void _updateCount(int delta) {
    _ticketAnimController.forward().then((_) {
      _ticketAnimController.reverse();
    });
    setState(() {
      final maxAllowed =
          _availableSeats <= 0 ? 1 : _availableSeats.clamp(1, 10);
      ticketCount = (ticketCount + delta).clamp(1, maxAllowed);
    });
  }

  void _proceedToPayment() {
    if (_isSoldOut) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PaymentScreen(
          event: widget.event,
          ticketCount: ticketCount,
          subtotal: subtotal,
          serviceFee: serviceFee,
          processingFee: processingFee,
          totalAmount: total,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seatPercentage = widget.event.totalSeats > 0
        ? (widget.event.bookedSeats / widget.event.totalSeats).clamp(0.0, 1.0)
        : 0.0;

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
                      onTap: () => Navigator.of(context).pop(),
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
                            'Checkout',
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
                            'Review your booking and proceed',
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

                // ── Event card ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.violet.withValues(alpha: 0.36),
                          ),
                        ),
                        child: Text(
                          widget.event.isPremium
                              ? 'PREMIUM EXPERIENCE'
                              : 'GENERAL ADMISSION',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.violet,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: EventImage(
                              event: widget.event,
                              height: 90,
                              width: 90,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.event.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                _InfoPill(
                                  icon: Icons.schedule_rounded,
                                  text:
                                      '${widget.event.date} · ${widget.event.time}',
                                ),
                                const SizedBox(height: 6),
                                _InfoPill(
                                  icon: Icons.location_on_outlined,
                                  text: widget.event.location,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Seat Availability ──
                if (widget.event.totalSeats > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isSoldOut
                                  ? Icons.block_rounded
                                  : Icons.event_seat_rounded,
                              color:
                                  _isSoldOut ? const Color(0xFFFF8A80) : AppColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSoldOut
                                  ? 'Sold Out'
                                  : '$_availableSeats of ${widget.event.totalSeats} seats remaining',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _isSoldOut
                                        ? const Color(0xFFFF8A80)
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: seatPercentage,
                            backgroundColor:
                                AppColors.surfaceStrong,
                            color: seatPercentage > 0.85
                                ? const Color(0xFFFF8A80)
                                : seatPercentage > 0.6
                                    ? Colors.orange
                                    : AppColors.accent,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Ticket selector ──
                Text(
                  'Select Tickets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'General Admission',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${widget.event.price} per ticket',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceStrong,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            _CounterButton(
                              icon: Icons.remove,
                              onTap: ticketCount > 1
                                  ? () => _updateCount(-1)
                                  : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: ScaleTransition(
                                scale: _ticketScale,
                                child: Text(
                                  ticketCount.toString().padLeft(2, '0'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                            _CounterButton(
                              icon: Icons.add,
                              onTap: ticketCount < _availableSeats.clamp(1, 10)
                                  ? () => _updateCount(1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Payment Summary ──
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Subtotal ($ticketCount Ticket${ticketCount > 1 ? 's' : ''})',
                        value: '₹${subtotal.toStringAsFixed(0)}',
                      ),
                      _SummaryRow(
                        label: 'Service Fee (5.5%)',
                        value: '₹$serviceFee',
                      ),
                      _SummaryRow(
                        label: 'Processing Fee (1.8%)',
                        value: '₹$processingFee',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: AppColors.border,
                          height: 1,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            '₹$total',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tax included where applicable. Secure SSL encrypted transaction.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
                const Spacer(),

                // ── Proceed button ──
                SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    child: ElevatedButton(
                      onPressed: _isSoldOut ? null : _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSoldOut
                            ? AppColors.surfaceStrong
                            : AppColors.accent,
                        foregroundColor: _isSoldOut
                            ? AppColors.textMuted
                            : AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isSoldOut ? 'Sold Out' : 'Proceed to Pay  ·  ₹$total',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.surfaceStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: enabled ? AppColors.accent : AppColors.textMuted,
          size: 18,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
