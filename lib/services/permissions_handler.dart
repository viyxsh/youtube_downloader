import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final sdkInt = await _getAndroidVersion();
    if (sdkInt >= 30) {
      // First request regular storage permission
      await Permission.storage.request();

      // For Android 11+, we need to check if we have the special permission
      // and direct users to the system screen if not
      if (!await Permission.manageExternalStorage.isGranted) {
        // This will open the special system screen for "All files access"
        await openAppSettings();

        // After returning from settings, we need to check again
        // Note: User needs to grant permission manually in settings
        return await Permission.manageExternalStorage.isGranted;
      }
      return true;
    }
    else {
      var storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
  }

  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      return int.parse(Platform.operatingSystemVersion.split(' ').last);
    } catch (e) {
      return Platform.version.contains('REL') ? 30 : 29;
    }
  }

  static Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdkInt = await _getAndroidVersion();

    if (sdkInt >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }
}