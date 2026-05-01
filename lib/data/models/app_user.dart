import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipTier { free, midnightPass }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.savedEventIds = const [],
    this.fcmToken = '',
    this.isAdmin = false,
    this.membershipTier = MembershipTier.free,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final List<String> savedEventIds;
  final String fcmToken;
  final bool isAdmin;
  final MembershipTier membershipTier;
  final DateTime createdAt;

  bool get isMidnightPassMember => membershipTier == MembershipTier.midnightPass;

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    List<String>? savedEventIds,
    String? fcmToken,
    bool? isAdmin,
    MembershipTier? membershipTier,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      savedEventIds: savedEventIds ?? this.savedEventIds,
      fcmToken: fcmToken ?? this.fcmToken,
      isAdmin: isAdmin ?? this.isAdmin,
      membershipTier: membershipTier ?? this.membershipTier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'savedEventIds': savedEventIds,
      'fcmToken': fcmToken,
      'isAdmin': isAdmin,
      'membershipTier': membershipTier.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      savedEventIds: List<String>.from(map['savedEventIds'] as List? ?? []),
      fcmToken: map['fcmToken'] as String? ?? '',
      isAdmin: map['isAdmin'] as bool? ?? false,
      membershipTier: MembershipTier.values.firstWhere(
        (t) => t.name == (map['membershipTier'] as String? ?? 'free'),
        orElse: () => MembershipTier.free,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.data() ?? {});
  }

  /// Creates a minimal user at sign-up time.
  factory AppUser.fromSignUp({
    required String uid,
    required String name,
    required String email,
  }) {
    return AppUser(
      uid: uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
  }
}
