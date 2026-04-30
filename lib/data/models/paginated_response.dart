import 'package:cloud_firestore/cloud_firestore.dart';

class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });

  final List<T> items;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}
