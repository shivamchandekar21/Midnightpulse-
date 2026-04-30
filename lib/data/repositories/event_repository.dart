import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/data/models/paginated_response.dart';
import 'package:midnight_pulse/data/services/event_firestore_service.dart';

abstract class EventRepository {
  Future<String> createEvent(Event event);

  Future<Event?> getEventById(String eventId);

  Future<PaginatedResponse<Event>> getEvents({
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    int limit = 10,
  });

  Stream<List<Event>> watchEvents({int limit = 10});

  Stream<Event?> watchEventById(String eventId);

  Future<void> updateEvent(Event event);

  Future<void> deleteEvent(String eventId);
}

class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository(this._service);

  final EventFirestoreService _service;

  Future<T> _guard<T>(Future<T> Function() callback) async {
    try {
      return await callback();
    } on AppException {
      rethrow;
    } catch (exception, stackTrace) {
      Error.throwWithStackTrace(
        AppException(
          message: 'Unexpected repository error while processing events.',
          cause: exception,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<String> createEvent(Event event) {
    return _guard(() => _service.createEvent(event));
  }

  @override
  Future<Event?> getEventById(String eventId) {
    return _guard(() => _service.getEventById(eventId));
  }

  @override
  Future<PaginatedResponse<Event>> getEvents({
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    int limit = 10,
  }) {
    return _guard(
      () => _service.fetchEventsPage(
        startAfterDocument: startAfterDocument,
        limit: limit,
      ),
    );
  }

  @override
  Stream<List<Event>> watchEvents({int limit = 10}) {
    return _service.watchEvents(limit: limit);
  }

  @override
  Stream<Event?> watchEventById(String eventId) {
    return _service.watchEventById(eventId);
  }

  @override
  Future<void> updateEvent(Event event) {
    return _guard(() => _service.updateEvent(event));
  }

  @override
  Future<void> deleteEvent(String eventId) {
    return _guard(() => _service.deleteEvent(eventId));
  }
}

class ResilientEventRepository implements EventRepository {
  ResilientEventRepository(this._remote, {List<Event>? fallbackEvents})
    : _fallbackStore = _LocalEventStore(fallbackEvents ?? _seedEvents());

  final EventRepository _remote;
  final _LocalEventStore _fallbackStore;
  bool _usingFallback = false;

  bool _shouldUseFallback(Object error) {
    final code = switch (error) {
      FirestoreException(:final code) => code,
      FirebaseException(:final code) => code,
      _ => null,
    };

    return code == 'permission-denied' ||
        code == 'unavailable' ||
        code == 'deadline-exceeded';
  }

  Future<T> _readWithFallback<T>({
    required Future<T> Function() remote,
    required FutureOr<T> Function() fallback,
  }) async {
    if (_usingFallback) {
      return fallback();
    }

    try {
      final value = await remote();
      _usingFallback = false;
      return value;
    } catch (error) {
      if (!_shouldUseFallback(error)) {
        rethrow;
      }

      _usingFallback = true;
      return fallback();
    }
  }

  Future<T> _writeWithFallback<T>({
    required Future<T> Function() remote,
    required FutureOr<T> Function() fallback,
  }) async {
    if (_usingFallback) {
      return fallback();
    }

    try {
      return await remote();
    } catch (error) {
      if (!_shouldUseFallback(error)) {
        rethrow;
      }

      _usingFallback = true;
      return fallback();
    }
  }

  @override
  Future<String> createEvent(Event event) {
    return _writeWithFallback(
      remote: () => _remote.createEvent(event),
      fallback: () => _fallbackStore.createEvent(event),
    );
  }

  @override
  Future<Event?> getEventById(String eventId) {
    return _readWithFallback(
      remote: () => _remote.getEventById(eventId),
      fallback: () => _fallbackStore.getEventById(eventId),
    );
  }

  @override
  Future<PaginatedResponse<Event>> getEvents({
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    int limit = 10,
  }) {
    return _readWithFallback(
      remote: () => _remote.getEvents(
        startAfterDocument: startAfterDocument,
        limit: limit,
      ),
      fallback: () => _fallbackStore.getEvents(),
    );
  }

  @override
  Stream<List<Event>> watchEvents({int limit = 10}) async* {
    if (_usingFallback) {
      yield _fallbackStore.watchEvents(limit: limit);
      return;
    }

    try {
      await for (final events in _remote.watchEvents(limit: limit)) {
        _usingFallback = false;
        yield events;
      }
    } catch (error) {
      if (!_shouldUseFallback(error)) {
        rethrow;
      }

      _usingFallback = true;
      yield _fallbackStore.watchEvents(limit: limit);
    }
  }

  @override
  Stream<Event?> watchEventById(String eventId) async* {
    if (_usingFallback) {
      yield await _fallbackStore.getEventById(eventId);
      return;
    }

    try {
      await for (final event in _remote.watchEventById(eventId)) {
        _usingFallback = false;
        yield event;
      }
    } catch (error) {
      if (!_shouldUseFallback(error)) {
        rethrow;
      }

      _usingFallback = true;
      yield await _fallbackStore.getEventById(eventId);
    }
  }

  @override
  Future<void> updateEvent(Event event) {
    return _writeWithFallback(
      remote: () => _remote.updateEvent(event),
      fallback: () => _fallbackStore.updateEvent(event),
    );
  }

  @override
  Future<void> deleteEvent(String eventId) {
    return _writeWithFallback(
      remote: () => _remote.deleteEvent(eventId),
      fallback: () => _fallbackStore.deleteEvent(eventId),
    );
  }

  static List<Event> _seedEvents() {
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);

    Event event({
      required String id,
      required String title,
      required String description,
      required int dayOffset,
      required int startHour,
      required String location,
      required int price,
      required String tag,
      bool isPremium = false,
    }) {
      final startDate = midnight.add(
        Duration(days: dayOffset, hours: startHour),
      );

      return Event(
        id: id,
        title: title,
        description: description,
        startDate: startDate,
        endDate: startDate.add(const Duration(hours: 5)),
        location: location,
        price: price,
        tag: tag,
        imageUrl: '',
        isPremium: isPremium,
        createdAt: today,
        updatedAt: today,
      );
    }

    return [
      event(
        id: 'local-neon-rooftop',
        title: 'Neon Rooftop Sessions',
        description:
            'Skyline house sets, reserved tables, and late-night bites.',
        dayOffset: 1,
        startHour: 21,
        location: 'Aurora Terrace',
        price: 1999,
        tag: 'Rooftop',
        isPremium: true,
      ),
      event(
        id: 'local-bassline',
        title: 'Bassline Underground',
        description:
            'Warehouse bass, immersive lights, and a packed dance floor.',
        dayOffset: 2,
        startHour: 22,
        location: 'Sector 12 Warehouse',
        price: 1499,
        tag: 'Club',
      ),
      event(
        id: 'local-afterglow',
        title: 'Afterglow Lounge',
        description: 'A velvet-room cocktail night with deep disco selectors.',
        dayOffset: 3,
        startHour: 20,
        location: 'The Velvet Room',
        price: 1299,
        tag: 'Lounge',
      ),
      event(
        id: 'local-synthwave',
        title: 'Synthwave Drive-In',
        description:
            'Retro visuals, live synths, and a midnight outdoor screen.',
        dayOffset: 4,
        startHour: 19,
        location: 'Moonlit Drive-In',
        price: 999,
        tag: 'Live',
      ),
      event(
        id: 'local-vip-pulse',
        title: 'Pulse VIP Blackout',
        description:
            'Premium bottle service, private booths, and headline DJs.',
        dayOffset: 5,
        startHour: 22,
        location: 'Midnight Pulse Club',
        price: 3499,
        tag: 'Premium',
        isPremium: true,
      ),
      event(
        id: 'local-dawn-chorus',
        title: 'Dawn Chorus Finale',
        description: 'Sunrise techno and coffee bar service for the last set.',
        dayOffset: 6,
        startHour: 23,
        location: 'Harbor Deck',
        price: 1799,
        tag: 'Festival',
      ),
    ];
  }
}

class _LocalEventStore {
  _LocalEventStore(List<Event> events)
    : _events = List<Event>.of(events)..sort(_sortByStartDate);

  final List<Event> _events;

  Future<String> createEvent(Event event) async {
    final now = DateTime.now();
    final id = event.id.isEmpty
        ? 'local-${now.microsecondsSinceEpoch}'
        : event.id;
    final localEvent = event.copyWith(
      id: id,
      createdAt: event.createdAt,
      updatedAt: now,
    );

    _events.add(localEvent);
    _events.sort(_sortByStartDate);

    return id;
  }

  Future<Event?> getEventById(String eventId) async {
    return _findEvent(eventId);
  }

  Future<PaginatedResponse<Event>> getEvents() async {
    return PaginatedResponse<Event>(items: _visibleEvents(), hasMore: false);
  }

  List<Event> watchEvents({required int limit}) {
    return _visibleEvents().take(limit).toList(growable: false);
  }

  Future<void> updateEvent(Event event) async {
    final index = _events.indexWhere((item) => item.id == event.id);
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());

    if (index == -1) {
      _events.add(updatedEvent);
    } else {
      _events[index] = updatedEvent;
    }

    _events.sort(_sortByStartDate);
  }

  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
  }

  Event? _findEvent(String eventId) {
    for (final event in _events) {
      if (event.id == eventId) {
        return event;
      }
    }

    return null;
  }

  List<Event> _visibleEvents() {
    return _events.where((event) => event.isActive).toList(growable: false);
  }

  static int _sortByStartDate(Event left, Event right) {
    return left.startDate.compareTo(right.startDate);
  }
}
