import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/data/models/app_user.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';

/// Real-time stream of the current user's [AppUser] document.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(userFirestoreServiceProvider).watchUser(uid);
});

/// Convenience: exposes the list of saved event IDs for the current user.
final savedEventIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(appUserProvider).value?.savedEventIds ?? [];
});

/// Fetches the current user's saved [Event] documents.
final savedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  return ref.watch(userFirestoreServiceProvider).getSavedEvents(uid);
});

// ─── Saved Event Toggle ──────────────────────────────────────────────────────

class SavedEventToggleNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> toggle(String eventId) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final savedIds = ref.read(savedEventIdsProvider);
    final service = ref.read(userFirestoreServiceProvider);

    state = const AsyncLoading();
    try {
      if (savedIds.contains(eventId)) {
        await service.unsaveEvent(uid, eventId);
      } else {
        await service.saveEvent(uid, eventId);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final savedEventToggleProvider =
    NotifierProvider.autoDispose<SavedEventToggleNotifier, AsyncValue<void>>(
      SavedEventToggleNotifier.new,
    );

// ─── Update User Profile ─────────────────────────────────────────────────────

class UpdateUserNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> update(Map<String, dynamic> fields) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    state = const AsyncLoading();
    try {
      await ref
          .read(userFirestoreServiceProvider)
          .updateUser(uid, {
            ...fields,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final updateUserProvider =
    NotifierProvider.autoDispose<UpdateUserNotifier, AsyncValue<void>>(
      UpdateUserNotifier.new,
    );
