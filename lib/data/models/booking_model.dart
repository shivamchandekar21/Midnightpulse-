import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    required this.imageUrl,
    required this.ticketCount,
    required this.subtotal,
    required this.serviceFee,
    required this.processingFee,
    required this.totalAmount,
    required this.bookingDate,
    this.status = BookingStatus.pending,
    this.paymentMethod = '',
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.qrData = '',
    this.cancelledAt,
  });

  final String id;
  final String userId;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String eventLocation;
  final String imageUrl;
  final int ticketCount;
  final int subtotal; // in paise
  final int serviceFee; // in paise
  final int processingFee; // in paise
  final int totalAmount; // in paise
  final DateTime bookingDate;
  final BookingStatus status;
  final String paymentMethod;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String qrData;
  final DateTime? cancelledAt;

  bool get isUpcoming => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isPending => status == BookingStatus.pending;

  /// Amount in rupees for display
  double get totalInRupees => totalAmount / 100;
  double get subtotalInRupees => subtotal / 100;

  String get displayStatus {
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? eventTitle,
    DateTime? eventDate,
    String? eventLocation,
    String? imageUrl,
    int? ticketCount,
    int? subtotal,
    int? serviceFee,
    int? processingFee,
    int? totalAmount,
    DateTime? bookingDate,
    BookingStatus? status,
    String? paymentMethod,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? qrData,
    DateTime? cancelledAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      imageUrl: imageUrl ?? this.imageUrl,
      ticketCount: ticketCount ?? this.ticketCount,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      processingFee: processingFee ?? this.processingFee,
      totalAmount: totalAmount ?? this.totalAmount,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      qrData: qrData ?? this.qrData,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventLocation': eventLocation,
      'imageUrl': imageUrl,
      'ticketCount': ticketCount,
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'processingFee': processingFee,
      'totalAmount': totalAmount,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'qrData': qrData,
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return BookingModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      eventTitle: map['eventTitle'] as String? ?? '',
      eventDate:
          (map['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventLocation: map['eventLocation'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      ticketCount: (map['ticketCount'] as num?)?.toInt() ?? 1,
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
      serviceFee: (map['serviceFee'] as num?)?.toInt() ?? 0,
      processingFee: (map['processingFee'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
      bookingDate:
          (map['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] as String? ?? '',
      razorpayOrderId: map['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: map['razorpayPaymentId'] as String? ?? '',
      qrData: map['qrData'] as String? ?? '',
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }

  factory BookingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BookingModel.fromMap(doc.data() ?? {}, id: doc.id);
  }
}
