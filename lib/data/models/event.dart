import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  const Event({
    this.id = '',
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.price,
    required this.tag,
    required this.imageUrl,
    this.isPremium = false,
    this.isActive = true,
    this.totalSeats = 0,
    this.bookedSeats = 0,
    this.averageRating = 0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final int price;
  final String tag;
  final String imageUrl;
  final bool isPremium;
  final bool isActive;
  final int totalSeats;
  final int bookedSeats;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get assetPath => imageUrl;

  String get subtitle => '$date, ${_formatTime(startDate)}';

  String get date => _formatDate(startDate);

  String get time => '${_formatTime(startDate)} - ${_formatTime(endDate)}';

  bool get usesLocalAsset => imageUrl.startsWith('assets/');

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    int? price,
    String? tag,
    String? imageUrl,
    bool? isPremium,
    bool? isActive,
    int? totalSeats,
    int? bookedSeats,
    double? averageRating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      price: price ?? this.price,
      tag: tag ?? this.tag,
      imageUrl: imageUrl ?? this.imageUrl,
      isPremium: isPremium ?? this.isPremium,
      isActive: isActive ?? this.isActive,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'price': price,
      'tag': tag,
      'imageUrl': imageUrl,
      'isPremium': isPremium,
      'isActive': isActive,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Event.fromMap(
    Map<String, dynamic> map, {
    String id = '',
  }) {
    final startDate =
        _readDateTime(map['startDate']) ??
        _readDateTime(map['date']) ??
        DateTime.now();
    final endDate =
        _readDateTime(map['endDate']) ?? startDate.add(const Duration(hours: 6));
    final createdAt = _readDateTime(map['createdAt']) ?? startDate;
    final updatedAt = _readDateTime(map['updatedAt']) ?? createdAt;

    return Event(
      id: id,
      title: map['title'] as String? ?? '',
      description:
          map['description'] as String? ?? map['subtitle'] as String? ?? '',
      startDate: startDate,
      endDate: endDate,
      location: map['location'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      tag: map['tag'] as String? ?? 'General',
      imageUrl: map['imageUrl'] as String? ??
          map['assetPath'] as String? ??
          'assets/driveripic.png',
      isPremium: map['isPremium'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 0,
      bookedSeats: (map['bookedSeats'] as num?)?.toInt() ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    return Event.fromMap(document.data() ?? <String, dynamic>{}, id: document.id);
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String _formatDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[value.month - 1];
    final day = value.day.toString().padLeft(2, '0');

    return '$month $day, ${value.year}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }
}
