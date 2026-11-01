import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Standard timeout duration across all Farmer Dost backend services (10 seconds).
const Duration kDefaultServiceTimeout = Duration(seconds: 10);

/// Shared utility to convert Firebase, network, and timeout exceptions into
/// farmer-friendly, user-facing error messages without ever throwing raw
/// technical stack traces to the UI layer.
class ServiceHelper {
  ServiceHelper._();

  /// Maps an exception to a clean, localized/user-facing message.
  static String mapErrorToUserMessage(Object error) {
    if (error is TimeoutException) {
      return 'The request took too long to complete. Please check your internet connection.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'network-request-failed':
          return 'Network offline. Please connect to mobile data or Wi-Fi.';
        case 'permission-denied':
          return 'Access restricted. Please sign in or verify your permissions.';
        case 'not-found':
          return 'The requested resource was not found.';
        case 'already-exists':
          return 'This record already exists.';
        case 'deadline-exceeded':
          return 'Connection timed out while contacting the server.';
        case 'unauthenticated':
          return 'You must be signed in to perform this action.';
        default:
          return error.message ?? 'A database error occurred (${error.code}).';
      }
    }

    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  /// Determines if an exception represents a network connectivity or timeout issue.
  static bool isNetworkError(Object error) {
    if (error is TimeoutException) return true;
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'network-request-failed' ||
          error.code == 'deadline-exceeded';
    }
    return false;
  }

  /// Determines if an exception represents a security rule permission denial.
  static bool isPermissionDenied(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }
    return false;
  }
}
