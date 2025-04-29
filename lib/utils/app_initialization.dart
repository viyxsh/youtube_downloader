import 'package:flutter/material.dart';
import 'package:youtube_downloader/services/permissions_handler.dart';

class AppInitialization {
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    await PermissionsHandler.requestStoragePermission();
  }
}