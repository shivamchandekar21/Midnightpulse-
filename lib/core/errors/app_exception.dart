import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.cause,
  });

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}

class FirestoreException extends AppException {
  const FirestoreException({
    required super.message,
    super.code,
    super.cause,
  });

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
