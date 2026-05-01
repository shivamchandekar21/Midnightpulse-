import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logEventViewed(String eventId, String title) {
    return _analytics.logEvent(
      name: 'event_viewed',
      parameters: {'event_id': eventId, 'title': title},
    );
  }

  static Future<void> logBookingStarted(String eventId) {
    return _analytics.logEvent(
      name: 'booking_started',
      parameters: {'event_id': eventId},
    );
  }

  static Future<void> logPaymentSuccess(int amountPaise, String method) {
    return _analytics.logEvent(
      name: 'payment_success',
      parameters: {'amount_paise': amountPaise, 'method': method},
    );
  }

  static Future<void> logPaymentFailed(String reason) {
    return _analytics.logEvent(
      name: 'payment_failed',
      parameters: {'reason': reason},
    );
  }
}
