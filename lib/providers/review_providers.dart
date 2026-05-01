import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/data/models/review_model.dart';
import 'package:midnight_pulse/data/services/review_firestore_service.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';
import 'package:midnight_pulse/providers/event_providers.dart';
import 'package:midnight_pulse/providers/user_providers.dart';

/// Provides the [ReviewFirestoreService].
final reviewFirestoreServiceProvider = Provider<ReviewFirestoreService>(
  (ref) => ReviewFirestoreService(ref.watch(firebaseFirestoreProvider)),
);

/// Real-time stream of reviews for a specific event.
final eventReviewsProvider =
    StreamProvider.autoDispose.family<List<ReviewModel>, String>(
      (ref, eventId) => ref
          .watch(reviewFirestoreServiceProvider)
          .watchEventReviews(eventId),
    );

/// Check if the current user has already reviewed a specific event.
final userReviewProvider =
    FutureProvider.autoDispose.family<ReviewModel?, String>((ref, eventId) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Future.value(null);
  return ref
      .watch(reviewFirestoreServiceProvider)
      .getUserReview(uid, eventId);
});

// ─── Submit Review ────────────────────────────────────────────────────────────

class SubmitReviewNotifier
    extends Notifier<AsyncValue<ReviewModel?>> {
  @override
  AsyncValue<ReviewModel?> build() => const AsyncData(null);

  Future<ReviewModel> submit({
    required String eventId,
    required double rating,
    required String comment,
  }) async {
    final uid = ref.read(currentUserIdProvider);
    final user = ref.read(appUserProvider).value;

    if (uid == null || user == null) {
      throw Exception('You must be signed in to submit a review.');
    }

    state = const AsyncLoading();

    final review = ReviewModel(
      id: '',
      userId: uid,
      userName: user.name,
      eventId: eventId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      userPhotoUrl: user.photoUrl,
    );

    try {
      final result =
          await ref.read(reviewFirestoreServiceProvider).addReview(review);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final submitReviewProvider =
    NotifierProvider.autoDispose<SubmitReviewNotifier, AsyncValue<ReviewModel?>>(
      SubmitReviewNotifier.new,
    );
