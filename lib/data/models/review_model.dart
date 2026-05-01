import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.eventId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userPhotoUrl = '',
  });

  final String id;
  final String userId;
  final String userName;
  final String eventId;
  final double rating; // 1.0 - 5.0
  final String comment;
  final DateTime createdAt;
  final String userPhotoUrl;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'eventId': eventId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'userPhotoUrl': userPhotoUrl,
    };
  }

  factory ReviewModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return ReviewModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous',
      eventId: map['eventId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] as String? ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userPhotoUrl: map['userPhotoUrl'] as String? ?? '',
    );
  }

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ReviewModel.fromMap(doc.data() ?? {}, id: doc.id);
  }
}
