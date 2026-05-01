import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayOrder {
  const RazorpayOrder({
    required this.id,
    required this.amount,
    required this.currency,
  });

  final String id;
  final int amount;
  final String currency;
}

class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
    this.method = '',
  });

  final String paymentId;
  final String orderId;
  final String signature;
  final String method;
}

class RazorpayService {
  static const String _defaultRazorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_change_me',
  );

  RazorpayService({
    Razorpay? razorpay,
    FirebaseFunctions? functions,
    String? keyId,
  })  : _razorpay = razorpay ?? Razorpay(),
        _functions = functions ?? FirebaseFunctions.instance,
        _keyId = keyId ?? _defaultRazorpayKey {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  final Razorpay _razorpay;
  final FirebaseFunctions _functions;
  final String _keyId;
  Completer<RazorpayPaymentResult>? _paymentCompleter;

  Future<RazorpayOrder> createOrder({
    required int amount,
    String currency = 'INR',
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    final callable = _functions.httpsCallable('createRazorpayOrder');
    final response = await callable.call(<String, dynamic>{
      'amount': amount,
      'currency': currency,
      'receipt': receipt,
      'notes': notes ?? const <String, dynamic>{},
    });

    final data = Map<String, dynamic>.from(response.data as Map);
    return RazorpayOrder(
      id: data['orderId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? amount,
      currency: data['currency'] as String? ?? currency,
    );
  }

  Future<void> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final callable = _functions.httpsCallable('verifyPayment');
    await callable.call(<String, dynamic>{
      'bookingId': bookingId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
  }

  Future<RazorpayPaymentResult> openCheckout({
    required RazorpayOrder order,
    required String name,
    required String description,
    required String prefillEmail,
    required String prefillContact,
  }) {
    _paymentCompleter = Completer<RazorpayPaymentResult>();
    _razorpay.open(<String, dynamic>{
      'key': _keyId,
      'amount': order.amount,
      'currency': order.currency,
      'name': name,
      'description': description,
      'order_id': order.id,
      'prefill': <String, dynamic>{
        'email': prefillEmail,
        'contact': prefillContact,
      },
      'theme': <String, dynamic>{'color': '#4FB8FF'},
    });
    return _paymentCompleter!.future;
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _paymentCompleter?.complete(
      RazorpayPaymentResult(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      ),
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _paymentCompleter?.completeError(
      Exception(response.message ?? 'Payment failed'),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _paymentCompleter?.completeError(
      Exception('External wallet selected: ${response.walletName ?? 'Unknown'}'),
    );
  }

  void dispose() {
    _razorpay.clear();
  }
}
