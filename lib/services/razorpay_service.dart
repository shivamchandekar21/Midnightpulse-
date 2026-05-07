import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
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

  // For Android emulator pointing to localhost, use 10.0.2.2.
  // For iOS simulator or web, use localhost.
  static const String _baseUrl = 'http://10.0.2.2:3000';

  RazorpayService({
    Razorpay? razorpay,
    String? keyId,
  })  : _razorpay = razorpay ?? Razorpay(),
        _keyId = keyId ?? _defaultRazorpayKey {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  final Razorpay _razorpay;
  final String _keyId;
  Completer<RazorpayPaymentResult>? _paymentCompleter;

  Future<RazorpayOrder> createOrder({
    required int amount,
    String currency = 'INR',
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    // 🔴 COMPLETELY MOCKING THE SERVER CALL 🔴
    // This allows testing the Flutter app without needing the Node.js server running!
    await Future.delayed(const Duration(milliseconds: 500));
    return RazorpayOrder(
      id: 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      currency: currency,
    );
  }

  Future<void> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    // 🔴 COMPLETELY MOCKING THE SERVER CALL 🔴
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate successful server verification
    return;
  }

  Future<RazorpayPaymentResult> openCheckout({
    required RazorpayOrder order,
    required String name,
    required String description,
    required String prefillEmail,
    required String prefillContact,
  }) {
    // If the server returned a stub order (dev mode), simulate a successful
    // payment so the developer can test flows without the Razorpay SDK.
    if (order.id.startsWith('order_stub_')) {
      final simulatedPaymentId = 'pay_stub_${DateTime.now().millisecondsSinceEpoch}';
      return Future.delayed(const Duration(seconds: 1), () {
        return RazorpayPaymentResult(
          paymentId: simulatedPaymentId,
          orderId: order.id,
          signature: 'sig_stub',
          method: 'upi',
        );
      });
    }

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
