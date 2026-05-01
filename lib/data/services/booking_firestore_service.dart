import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';
import 'package:midnight_pulse/data/models/booking_model.dart';
import 'package:midnight_pulse/data/models/payment_model.dart';
import 'package:uuid/uuid.dart';

class BookingFirestoreService {
  BookingFirestoreService(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _bookingsRef =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');

  /// Creates a booking and atomically decrements event seat count.
  /// Returns the newly created [BookingModel] with its Firestore ID.
  Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      final bookingId = _uuid.v4();
      final bookingRef = _bookingsRef.doc(bookingId);
      final eventRef = _eventsRef.doc(booking.eventId);

      await _firestore.runTransaction((transaction) async {
        final eventSnap = await transaction.get(eventRef);

        if (!eventSnap.exists) {
          throw AppException('Event not found.', code: 'event-not-found');
        }

        final data = eventSnap.data()!;
        final totalSeats = (data['totalSeats'] as num?)?.toInt() ?? 0;
        final bookedSeats = (data['bookedSeats'] as num?)?.toInt() ?? 0;
        final available = totalSeats - bookedSeats;

        if (totalSeats > 0 && available < booking.ticketCount) {
          throw AppException(
            'Not enough seats available. Only $available left.',
            code: 'insufficient-seats',
          );
        }

        final bookingWithId = booking.copyWith(id: bookingId);
        final qrData = 'MP-${bookingId.substring(0, 8).toUpperCase()}';

        transaction.set(
          bookingRef,
          bookingWithId.copyWith(qrData: qrData).toMap(),
        );

        if (totalSeats > 0) {
          transaction.update(eventRef, {
            'bookedSeats': FieldValue.increment(booking.ticketCount),
          });
        }
      });

      final created = await bookingRef.get();
      return BookingModel.fromFirestore(created);
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Stream of all bookings for a given user (real-time).
  Stream<List<BookingModel>> watchUserBookings(String userId) {
    return _bookingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(BookingModel.fromFirestore).toList(),
        )
        .handleError((Object e) {
          throw AppException.fromFirestore(e);
        });
  }

  /// Fetches all bookings for a user once.
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snap = await _bookingsRef
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .get();
      return snap.docs.map(BookingModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Get a single booking by ID.
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsRef.doc(bookingId).get();
      if (!doc.exists) return null;
      return BookingModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Update booking status (e.g., confirmed after payment, completed after event).
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? paymentMethod,
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    try {
      final fields = <String, dynamic>{'status': status.name};
      if (paymentMethod != null) fields['paymentMethod'] = paymentMethod;
      if (razorpayPaymentId != null) {
        fields['razorpayPaymentId'] = razorpayPaymentId;
      }
      if (razorpayOrderId != null) {
        fields['razorpayOrderId'] = razorpayOrderId;
      }
      await _bookingsRef.doc(bookingId).update(fields);
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  Future<void> createPayment(PaymentModel payment) async {
    try {
      await _paymentsRef.doc(payment.id).set(payment.toMap());
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Cancel a booking and restore seat count atomically.
  Future<void> cancelBooking(String bookingId) async {
    try {
      final bookingRef = _bookingsRef.doc(bookingId);

      await _firestore.runTransaction((transaction) async {
        final bookingSnap = await transaction.get(bookingRef);
        if (!bookingSnap.exists) return;

        final booking = BookingModel.fromFirestore(bookingSnap);
        if (booking.isCancelled) return;

        final eventRef = _eventsRef.doc(booking.eventId);
        final eventSnap = await transaction.get(eventRef);

        transaction.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        if (eventSnap.exists) {
          transaction.update(eventRef, {
            'bookedSeats':
                FieldValue.increment(-booking.ticketCount),
          });
        }
      });
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }
}
