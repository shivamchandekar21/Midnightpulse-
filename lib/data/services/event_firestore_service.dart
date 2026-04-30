import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:midnight_pulse/core/constants/firestore_collections.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/data/models/paginated_response.dart';
import 'package:midnight_pulse/data/services/firestore_service.dart';

class EventFirestoreService extends FirestoreService {
  EventFirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection(FirestoreCollections.events);

  Query<Map<String, dynamic>> _query({
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _eventsCollection.orderBy('startDate');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  Future<String> createEvent(Event event) async {
    try {
      final document = _eventsCollection.doc();

      await document.set({
        ...event.copyWith(id: document.id).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return document.id;
    } on FirebaseException catch (exception, stackTrace) {
      throwFirebaseException(
        exception,
        operation: 'create an event',
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      throwUnknownException(
        exception,
        operation: 'create an event',
        stackTrace: stackTrace,
      );
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      final document = await _eventsCollection.doc(eventId).get();

      if (!document.exists) {
        return null;
      }

      return Event.fromFirestore(document);
    } on FirebaseException catch (exception, stackTrace) {
      throwFirebaseException(
        exception,
        operation: 'fetch the event',
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      throwUnknownException(
        exception,
        operation: 'fetch the event',
        stackTrace: stackTrace,
      );
    }
  }

  Future<PaginatedResponse<Event>> fetchEventsPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _query(limit: limit);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      final events = snapshot.docs.map(Event.fromFirestore).toList();

      return PaginatedResponse<Event>(
        items: events,
        hasMore: snapshot.docs.length == limit,
        lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      );
    } on FirebaseException catch (exception, stackTrace) {
      throwFirebaseException(
        exception,
        operation: 'load events',
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      throwUnknownException(
        exception,
        operation: 'load events',
        stackTrace: stackTrace,
      );
    }
  }

  Stream<List<Event>> watchEvents({
    int limit = 10,
  }) {
    try {
      return _query(limit: limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(Event.fromFirestore).toList());
    } on FirebaseException catch (exception, stackTrace) {
      throwFirebaseException(
        exception,
        operation: 'watch events',
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      throwUnknownException(
        exception,
        operation: 'watch events',
        stackTrace: stackTrace,
      );
    }
  }

  Stream<Event?> watchEventById(String eventId) {
    try {
      return _eventsCollection.doc(eventId).snapshots().map((document) {
        if (!document.exists || document.data() == null) {
          return null;
        }

        return Event.fromFirestore(document);
      });
    } on FirebaseException catch (exception, stackTrace) {
      throwFirebaseException(
        exception,
        operation: 'watch the event',
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      throwUnknownException(
        exception,
        operation: 'watch the event',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> updateEvent(Event event) async {
    if (event.id.isEmpty) {
      throw const AppException(
        message: 'Cannot update an event without a document id.',
      );
    }

    try {
      final payload = event.toMap()
        ..remove('createdAt')
        ..remove('updatedAt');

      await _eventsCollection.doc(event.id).update({
        ...payload,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (exception, stackTrace) {
      throwFirebaseException(
        exception,
        operation: 'update the event',
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      throwUnknownException(
        exception,
        operation: 'update the event',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } on FirebaseException catch (exception, stackTrace) {
      throwFirebaseException(
        exception,
        operation: 'delete the event',
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      throwUnknownException(
        exception,
        operation: 'delete the event',
        stackTrace: stackTrace,
      );
    }
  }
}
