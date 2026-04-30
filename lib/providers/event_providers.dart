import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/data/repositories/event_repository.dart';
import 'package:midnight_pulse/data/services/event_firestore_service.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final eventFirestoreServiceProvider = Provider<EventFirestoreService>(
  (ref) => EventFirestoreService(ref.watch(firebaseFirestoreProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => ResilientEventRepository(
    FirestoreEventRepository(ref.watch(eventFirestoreServiceProvider)),
  ),
);

final liveEventsProvider = StreamProvider.autoDispose<List<Event>>(
  (ref) => ref.watch(eventRepositoryProvider).watchEvents(limit: 10),
);

final eventStreamProvider = StreamProvider.autoDispose.family<Event?, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).watchEventById(eventId),
);

final eventFiltersProvider =
    NotifierProvider<EventFiltersNotifier, EventFiltersState>(
      EventFiltersNotifier.new,
    );

final eventsControllerProvider =
    AsyncNotifierProvider<EventsController, EventListState>(
      EventsController.new,
    );

final availableEventFiltersProvider = Provider<List<String>>((ref) {
  final events = ref.watch(eventsControllerProvider).valueOrNull?.items ?? [];
  final uniqueTags =
      events
          .map((event) => event.tag.trim())
          .where((tag) => tag.isNotEmpty && tag.toLowerCase() != 'premium')
          .toSet()
          .toList()
        ..sort();

  return ['All Nights', ...uniqueTags, 'Premium'];
});

final filteredEventsStateProvider = Provider<AsyncValue<EventListState>>((ref) {
  final filters = ref.watch(eventFiltersProvider);
  final eventsState = ref.watch(eventsControllerProvider);

  return eventsState.whenData((state) {
    final query = filters.searchQuery.trim().toLowerCase();
    final filteredItems = state.items.where((event) {
      final matchesSearch =
          query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.tag.toLowerCase().contains(query);

      final matchesFilter =
          filters.selectedFilter == 'All Nights' ||
          event.tag.toLowerCase() == filters.selectedFilter.toLowerCase() ||
          (filters.selectedFilter == 'Premium' && event.isPremium);

      return matchesSearch && matchesFilter;
    }).toList();

    return state.copyWith(items: filteredItems);
  });
});

class EventFiltersState {
  const EventFiltersState({
    this.selectedFilter = 'All Nights',
    this.searchQuery = '',
  });

  final String selectedFilter;
  final String searchQuery;

  bool get hasActiveFilters =>
      selectedFilter != 'All Nights' || searchQuery.trim().isNotEmpty;

  EventFiltersState copyWith({String? selectedFilter, String? searchQuery}) {
    return EventFiltersState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class EventFiltersNotifier extends Notifier<EventFiltersState> {
  @override
  EventFiltersState build() => const EventFiltersState();

  void selectFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = const EventFiltersState();
  }
}

class EventListState {
  const EventListState({
    required this.items,
    required this.hasMore,
    this.lastDocument,
    this.isLoadingMore = false,
  });

  final List<Event> items;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool isLoadingMore;

  EventListState copyWith({
    List<Event>? items,
    bool? hasMore,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? isLoadingMore,
  }) {
    return EventListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class EventsController extends AsyncNotifier<EventListState> {
  static const int _pageSize = 6;

  EventRepository get _repository => ref.read(eventRepositoryProvider);

  @override
  Future<EventListState> build() {
    return _fetchFirstPage();
  }

  Future<EventListState> _fetchFirstPage() async {
    final page = await _repository.getEvents(limit: _pageSize);

    return EventListState(
      items: page.items,
      hasMore: page.hasMore,
      lastDocument: page.lastDocument,
    );
  }

  Future<void> refreshEvents() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;

    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.getEvents(
        startAfterDocument: currentState.lastDocument,
        limit: _pageSize,
      );

      state = AsyncData(
        EventListState(
          items: [...currentState.items, ...page.items],
          hasMore: page.hasMore,
          lastDocument: page.lastDocument ?? currentState.lastDocument,
          isLoadingMore: false,
        ),
      );
    } on AppException {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> createEvent(Event event) async {
    final currentState = state.valueOrNull;

    try {
      await _repository.createEvent(event);
      await refreshEvents();
    } on AppException {
      if (currentState != null) {
        state = AsyncData(currentState);
      }
      rethrow;
    }
  }

  Future<void> updateEvent(Event event) async {
    final currentState = state.valueOrNull;

    try {
      await _repository.updateEvent(event);
      await refreshEvents();
    } on AppException {
      if (currentState != null) {
        state = AsyncData(currentState);
      }
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final currentState = state.valueOrNull;

    try {
      await _repository.deleteEvent(eventId);
      await refreshEvents();
    } on AppException {
      if (currentState != null) {
        state = AsyncData(currentState);
      }
      rethrow;
    }
  }
}
