import 'package:flutter/material.dart';
import 'package:youtube_downloader/services/permissions_handler.dart';
import 'package:youtube_downloader/widgets/storage_permission_dialog.dart';

class AppInitialization {
  static Future<void> initializeApp(GlobalKey<NavigatorState> navigatorKey) async {
    WidgetsFlutterBinding.ensureInitialized();

    bool hasPermission = await PermissionsHandler.requestStoragePermission();

    if (!hasPermission && navigatorKey.currentContext != null) {
      await StoragePermissionDialog.showPermissionDialog(navigatorKey.currentContext!);
    }

  }
}