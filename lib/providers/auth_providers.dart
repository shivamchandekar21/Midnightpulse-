import 'dart:async';
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

class AuthActionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final error = await authService.signIn(email: email, password: password);
      if (error != null) {
        state = AsyncError(error, StackTrace.current);
        throw Exception(error);
      } else {
        state = const AsyncData(null);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signUp({required String email, required String password, required String name}) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final error = await authService.signUp(email: email, password: password);
      if (error != null) {
        state = AsyncError(error, StackTrace.current);
        throw Exception(error);
      } else {
        final user = authService.currentUser;
        if (user != null) {
          await ref.read(firebaseFirestoreProvider).collection('users').doc(user.uid).update({'name': name});
        }
        state = const AsyncData(null);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final signInProvider = AsyncNotifierProvider.autoDispose<AuthActionNotifier, void>(AuthActionNotifier.new);

final signUpProvider = AsyncNotifierProvider.autoDispose<AuthActionNotifier, void>(AuthActionNotifier.new);
