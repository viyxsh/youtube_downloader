import 'dart:async';
import 'package:flutter/material.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    debugPrint('Original error: $error');

    return 'Something went wrong. Please try again.';
  }

  static String getDetailedErrorMessage(dynamic error) {
    if (error == null) {
      return 'Unknown error occurred';
    }

    if (error is TimeoutException) {
      return 'Connection timed out. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid format. Please check your input.';
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('null') && errorString.contains('string')) {
      return 'Invalid data received. Please try again.';
    } else if (errorString.contains('videounavailable')) {
      return 'This video is unavailable or private.';
    } else if (errorString.contains('httpclient') || errorString.contains('socket')) {
      return 'Network error. Please check your connection.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    } else if (errorString.contains('storage')) {
      return 'Storage error. Please check available space.';
    }

    return 'An error occurred: ${error.toString()}';
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  static void showErrorDialog(BuildContext context, String message) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Something went wrong. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  static Future<T?> safeExecute<T>(
      Future<T> Function() operation,
      Function(String errorMessage) onError,
      ) async {
    try {
      return await operation();
    } catch (e) {
      debugPrint('Error caught in safeExecute: $e');
      onError('Something went wrong. Please try again.');
      return null;
    }
  }
}