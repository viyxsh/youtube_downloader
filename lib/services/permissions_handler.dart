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
      var storageStatus = await Permission.storage.request();
      var manageStatus = await Permission.manageExternalStorage.request();

      if (!manageStatus.isGranted) {
        debugPrint('MANAGE_EXTERNAL_STORAGE permission denied');
        return false;
      }

      return manageStatus.isGranted;
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