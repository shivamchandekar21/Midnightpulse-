import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/data/models/booking_model.dart';
import 'package:midnight_pulse/data/models/payment_model.dart';
import 'package:midnight_pulse/data/services/booking_firestore_service.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';
import 'package:midnight_pulse/providers/event_providers.dart';

/// Provides the [BookingFirestoreService].
final bookingFirestoreServiceProvider = Provider<BookingFirestoreService>(
  (ref) => BookingFirestoreService(ref.watch(firebaseFirestoreProvider)),
);

/// Real-time stream of all bookings for the current user.
final userBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref
      .watch(bookingFirestoreServiceProvider)
      .watchUserBookings(uid);
});

/// Derived: upcoming (confirmed) bookings.
final upcomingBookingsProvider = Provider<List<BookingModel>>((ref) {
  final bookings = ref.watch(userBookingsProvider).value ?? [];
  return bookings.where((b) => b.status == BookingStatus.confirmed).toList();
});

/// Derived: past (completed) bookings.
final pastBookingsProvider = Provider<List<BookingModel>>((ref) {
  final bookings = ref.watch(userBookingsProvider).value ?? [];
  return bookings.where((b) => b.status == BookingStatus.completed).toList();
});

/// Derived: cancelled bookings.
final cancelledBookingsProvider = Provider<List<BookingModel>>((ref) {
  final bookings = ref.watch(userBookingsProvider).value ?? [];
  return bookings.where((b) => b.status == BookingStatus.cancelled).toList();
});

// ─── Create Booking ───────────────────────────────────────────────────────────

class CreateBookingNotifier
    extends Notifier<AsyncValue<BookingModel?>> {
  @override
  AsyncValue<BookingModel?> build() => const AsyncData(null);

  /// Creates a booking in Firestore atomically with seat decrement.
  Future<BookingModel> create(BookingModel booking) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(bookingFirestoreServiceProvider)
          .createBooking(booking);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Updates the booking status after payment confirmed.
  Future<void> confirmPayment({
    required String bookingId,
    required String paymentMethod,
    required String razorpayPaymentId,
    required String razorpayOrderId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(bookingFirestoreServiceProvider)
          .updateBookingStatus(
            bookingId,
            BookingStatus.confirmed,
            paymentMethod: paymentMethod,
            razorpayPaymentId: razorpayPaymentId,
            razorpayOrderId: razorpayOrderId,
          );
      state = AsyncData(state.value);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createPayment(PaymentModel payment) async {
    await ref.read(bookingFirestoreServiceProvider).createPayment(payment);
  }
}

final createBookingProvider =
    NotifierProvider.autoDispose<CreateBookingNotifier, AsyncValue<BookingModel?>>(
      CreateBookingNotifier.new,
    );

// ─── Cancel Booking ───────────────────────────────────────────────────────────

class CancelBookingNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> cancel(String bookingId) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(bookingFirestoreServiceProvider)
          .cancelBooking(bookingId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final cancelBookingProvider =
    NotifierProvider.autoDispose<CancelBookingNotifier, AsyncValue<void>>(
      CancelBookingNotifier.new,
    );
