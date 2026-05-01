import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';
import 'package:midnight_pulse/data/models/review_model.dart';

class ReviewFirestoreService {
  ReviewFirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection('reviews');

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  /// Submit a new review and update the event's aggregated rating.
  Future<ReviewModel> addReview(ReviewModel review) async {
    try {
      final reviewRef = _reviewsRef.doc();
      final eventRef = _eventsRef.doc(review.eventId);

      await _firestore.runTransaction((transaction) async {
        final eventSnap = await transaction.get(eventRef);

        transaction.set(reviewRef, review.toMap());

        if (eventSnap.exists) {
          final data = eventSnap.data()!;
          final currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
          final currentAvg = (data['averageRating'] as num?)?.toDouble() ?? 0.0;

          final newCount = currentCount + 1;
          final newAvg =
              ((currentAvg * currentCount) + review.rating) / newCount;

          transaction.update(eventRef, {
            'reviewCount': newCount,
            'averageRating': double.parse(newAvg.toStringAsFixed(1)),
          });
        }
      });

      final created = await reviewRef.get();
      return ReviewModel.fromFirestore(created);
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Stream of reviews for a specific event.
  Stream<List<ReviewModel>> watchEventReviews(String eventId) {
    return _reviewsRef
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map(ReviewModel.fromFirestore).toList(),
        )
        .handleError((Object e) {
          throw AppException.fromFirestore(e);
        });
  }

  /// Check if a user has already reviewed a specific event.
  Future<ReviewModel?> getUserReview(String userId, String eventId) async {
    try {
      final snap = await _reviewsRef
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return ReviewModel.fromFirestore(snap.docs.first);
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }
}
