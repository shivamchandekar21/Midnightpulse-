import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/auth/auth_service.dart';
import 'package:midnight_pulse/data/services/user_firestore_service.dart';
import 'package:midnight_pulse/providers/event_providers.dart';

/// Provides the singleton [AuthService].
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream of the currently signed-in [User]. Null means signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Convenience provider: returns the current user's uid or null.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// Provides the [UserFirestoreService].
final userFirestoreServiceProvider = Provider<UserFirestoreService>(
  (ref) => UserFirestoreService(ref.watch(firebaseFirestoreProvider)),
);
