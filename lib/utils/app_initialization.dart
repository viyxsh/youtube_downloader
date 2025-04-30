import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_downloader/services/permissions_handler.dart';
import 'package:youtube_downloader/widgets/storage_permission_dialog.dart';

class AppInitialization {
  static Future<void> initializeApp(GlobalKey<NavigatorState> navigatorKey) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Only proceed with permission requests on Android
    if (Platform.isAndroid) {
      debugPrint('Initializing app and requesting permissions');

      // First attempt to request permissions programmatically
      bool hasPermission = await PermissionsHandler.requestStoragePermission();
      debugPrint('Initial permission request result: $hasPermission');

      // If we still don't have permissions and have a valid context, show the dialog
      if (!hasPermission && navigatorKey.currentContext != null) {
        debugPrint('Showing permission dialog');

        // Slight delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 500));

        // Show permission dialog
        await StoragePermissionDialog.showPermissionDialog(navigatorKey.currentContext!);

        // Check if permissions were granted after dialog
        hasPermission = await PermissionsHandler.checkStoragePermission();
        debugPrint('Permission status after dialog: $hasPermission');
      }
    }
  }
}