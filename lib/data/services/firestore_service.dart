import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:midnight_pulse/core/errors/app_exception.dart';

abstract class FirestoreService {
  const FirestoreService();

  @protected
  Never throwFirebaseException(
    FirebaseException exception, {
    required String operation,
    required StackTrace stackTrace,
  }) {
    Error.throwWithStackTrace(
      FirestoreException.fromFirebase(
        exception,
        operation: operation,
      ),
      stackTrace,
    );
  }

  @protected
  Never throwUnknownException(
    Object exception, {
    required String operation,
    required StackTrace stackTrace,
  }) {
    Error.throwWithStackTrace(
      FirestoreException(
        message: 'Unexpected error while trying to $operation.',
        cause: exception,
      ),
      stackTrace,
    );
  }
}
