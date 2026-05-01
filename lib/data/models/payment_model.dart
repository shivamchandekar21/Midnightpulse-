import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { created, authorized, captured, failed, refunded }

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.createdAt,
    this.currency = 'INR',
    this.status = PaymentStatus.created,
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.razorpaySignature = '',
    this.method = '',
  });

  final String id;
  final String bookingId;
  final String userId;
  final int amount; // in paise
  final String currency;
  final PaymentStatus status;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final String method;
  final DateTime createdAt;

  double get amountInRupees => amount / 100;

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'method': method,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return PaymentModel(
      id: id,
      bookingId: map['bookingId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      currency: map['currency'] as String? ?? 'INR',
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'created'),
        orElse: () => PaymentStatus.created,
      ),
      razorpayOrderId: map['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: map['razorpayPaymentId'] as String? ?? '',
      razorpaySignature: map['razorpaySignature'] as String? ?? '',
      method: map['method'] as String? ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PaymentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return PaymentModel.fromMap(doc.data() ?? {}, id: doc.id);
  }
}
