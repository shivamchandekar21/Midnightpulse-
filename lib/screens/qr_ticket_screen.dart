import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:midnight_pulse/data/models/booking_model.dart';
import 'package:midnight_pulse/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class QrTicketScreen extends StatefulWidget {
  const QrTicketScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  State<QrTicketScreen> createState() => _QrTicketScreenState();
}

class _QrTicketScreenState extends State<QrTicketScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _ticketKey = GlobalKey();
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _shareTicket() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary = _ticketKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/midnight_pulse_ticket_${widget.booking.id.substring(0, 8)}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          text:
              '🎫 My Midnight Pulse ticket for ${widget.booking.eventTitle}',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final qrPayload = booking.qrData.isNotEmpty ? booking.qrData : booking.id;
    final ticketId = booking.qrData.isNotEmpty
        ? (booking.qrData.length > 24
            ? 'MP-${booking.id.substring(0, 8).toUpperCase()}'
            : booking.qrData)
        : booking.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
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
                            'Your Ticket',
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
                            'Show this QR code at the venue',
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
                const SizedBox(height: 24),

                // ── Ticket card ──
                Expanded(
                  child: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: _ticketKey,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppGradients.panel,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top section — event info
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  children: [
                                    // Brand pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.violet
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.violet
                                              .withValues(alpha: 0.36),
                                        ),
                                      ),
                                      child: Text(
                                        'MIDNIGHT PULSE',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.violet,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      booking.eventTitle,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      booking.eventLocation,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tear separator
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.background,
                                    ),
                                  ),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final dashCount =
                                            (constraints.maxWidth / 10).floor();
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: List.generate(dashCount,
                                              (index) {
                                            return Container(
                                              width: 5,
                                              height: 1.5,
                                              color: AppColors.border,
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.background,
                                    ),
                                  ),
                                ],
                              ),

                              // QR section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  children: [
                                    // QR code
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: QrImageView(
                                        data: qrPayload,
                                        size: 220,
                                        backgroundColor: Colors.white,
                                        errorCorrectionLevel:
                                            QrErrorCorrectLevel.H,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF0C1326),
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                          dataModuleShape:
                                              QrDataModuleShape.square,
                                          color: Color(0xFF0C1326),
                                        ),
                                        errorStateBuilder: (_, __) =>
                                            const SizedBox(
                                          height: 220,
                                          width: 220,
                                          child: Center(
                                            child: Text('QR unavailable'),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Ticket ID
                                    Text(
                                      ticketId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),

                                    // Details row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _TicketDetail(
                                          label: 'DATE',
                                          value: _formatDate(
                                              booking.eventDate),
                                        ),
                                        Container(
                                          height: 30,
                                          width: 1,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          color: AppColors.border,
                                        ),
                                        _TicketDetail(
                                          label: 'TIME',
                                          value: _formatTime(
                                              booking.eventDate),
                                        ),
                                        Container(
                                          height: 30,
                                          width: 1,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          color: AppColors.border,
                                        ),
                                        _TicketDetail(
                                          label: 'TICKETS',
                                          value:
                                              '${booking.ticketCount}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Share / Download button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor: AppColors.surfaceStrong,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: _isSharing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      _isSharing ? 'Preparing...' : 'Share Ticket',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

  String _formatDate(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[value.month - 1];
    final day = value.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final min = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $suffix';
  }
}

class _TicketDetail extends StatelessWidget {
  const _TicketDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
