import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.cause,
  });

  final String message;
  final String? code;
  final Object? cause;

  factory AppException.fromFirestore(Object e) {
    if (e is FirebaseException) {
      return AppException(
        _buildFirebaseMessage(e),
        code: e.code,
        cause: e,
      );
    }
    if (e is AppException) return e;
    return AppException(e.toString(), cause: e);
  }

  static String _buildFirebaseMessage(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return 'Permission denied. Please log in again.';
      case 'unavailable':
        return 'Service unavailable. Please try again.';
      case 'not-found':
        return 'The requested document was not found.';
      case 'already-exists':
        return 'A document for this request already exists.';
      case 'cancelled':
        return 'The request was cancelled.';
      case 'deadline-exceeded':
        return 'The request timed out. Please try again.';
      default:
        return exception.message ?? 'An unexpected error occurred.';
    }
  }

  @override
  String toString() => message;
}

class FirestoreException extends AppException {
  const FirestoreException({
    required String message,
    String? code,
    Object? cause,
  }) : super(message, code: code, cause: cause);

  factory FirestoreException.fromFirebase(
    FirebaseException exception, {
    required String operation,
  }) {
    return FirestoreException(
      code: exception.code,
      cause: exception,
      message: _buildMessage(exception, operation),
    );
  }

  static String _buildMessage(
    FirebaseException exception,
    String operation,
  ) {
    switch (exception.code) {
      case 'permission-denied':
        return 'Permission denied while trying to $operation.';
      case 'unavailable':
        return 'Firestore is currently unavailable. Please try again.';
      case 'not-found':
        return 'The requested document was not found.';
      case 'already-exists':
        return 'A document for this request already exists.';
      case 'cancelled':
        return 'The request was cancelled before Firestore completed it.';
      case 'deadline-exceeded':
        return 'The Firestore request timed out while trying to $operation.';
      default:
        return exception.message ?? 'Failed to $operation.';
    }
  }
}
