import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';
import 'package:midnight_pulse/data/models/app_user.dart';
import 'package:midnight_pulse/data/models/event.dart';

class UserFirestoreService {
  UserFirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Watch a user document as a real-time stream.
  Stream<AppUser?> watchUser(String uid) {
    return _usersRef
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists ? AppUser.fromMap(doc.data()!) : null,
        )
        .handleError((Object e) {
          throw AppException.fromFirestore(e);
        });
  }

  /// Get a user document once.
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Create or fully overwrite a user document.
  Future<void> createUser(AppUser user) async {
    try {
      await _usersRef.doc(user.uid).set(user.toMap());
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Merge-update specific fields for a user.
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    try {
      await _usersRef.doc(uid).update(fields);
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Save an event to the user's saved list.
  Future<void> saveEvent(String uid, String eventId) async {
    try {
      await _usersRef.doc(uid).update({
        'savedEventIds': FieldValue.arrayUnion([eventId]),
      });
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Remove an event from the user's saved list.
  Future<void> unsaveEvent(String uid, String eventId) async {
    try {
      await _usersRef.doc(uid).update({
        'savedEventIds': FieldValue.arrayRemove([eventId]),
      });
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Fetch all saved events for a user.
  Future<List<Event>> getSavedEvents(String uid) async {
    try {
      final user = await getUser(uid);
      final ids = user?.savedEventIds ?? <String>[];

      if (ids.isEmpty) {
        return const [];
      }

      final events = <Event>[];
      for (final id in ids) {
        final eventDoc = await _firestore.collection('events').doc(id).get();
        if (eventDoc.exists) {
          events.add(Event.fromFirestore(eventDoc));
        }
      }

      return events;
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Update the FCM token for push notifications.
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _usersRef.doc(uid).update({'fcmToken': token});
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }

  /// Check if user doc exists (used after social login to avoid overwriting).
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw AppException.fromFirestore(e);
    }
  }
}
