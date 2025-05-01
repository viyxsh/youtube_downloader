import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Add this dependency to pubspec.yaml

class PermissionsHandler {
  // Cache the Android SDK version to avoid repeated queries
  static int? _cachedAndroidSdk;

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      debugPrint("DEBUG: Not Android platform, returning true");
      return true;
    }

    final sdkInt = await _getAndroidSdkVersion();
    debugPrint("DEBUG: Android SDK version: $sdkInt");

    // For Android 10 and below (API 29-)
    if (sdkInt <= 29) {
      debugPrint("DEBUG: Requesting legacy storage permission for SDK <= 29");
      final status = await Permission.storage.request();
      debugPrint("DEBUG: Legacy storage permission status: ${status.isGranted}");
      return status.isGranted;
    }
    // For Android 11+ (API 30+)
    else {
      // For Android 11+, check MANAGE_EXTERNAL_STORAGE first
      final manageStatus = await Permission.manageExternalStorage.status;
      debugPrint("DEBUG: Initial MANAGE_EXTERNAL_STORAGE status: ${manageStatus.isGranted}");

      // If MANAGE_EXTERNAL_STORAGE is already granted, we're good to go
      if (manageStatus.isGranted) {
        debugPrint("DEBUG: MANAGE_EXTERNAL_STORAGE already granted, returning true");
        return true;
      }

      // Otherwise, request it
      debugPrint("DEBUG: Requesting MANAGE_EXTERNAL_STORAGE permission");
      bool result = await Permission.manageExternalStorage.request().isGranted;

      // If the direct request didn't work (as expected), open settings
      if (!result) {
        debugPrint("DEBUG: Opening app settings for MANAGE_EXTERNAL_STORAGE permission");
        await openAppSettings();
        // We'll need to check the permission after user returns from settings
        // but we can't do that here since we don't know when they'll return
        debugPrint("DEBUG: Opened app settings, can't verify permission yet");
        // Return true to avoid showing the dialog immediately
        // The permission will be checked again next time
        return true;
      }

      return result;
    }
  }

  static Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) {
      debugPrint("DEBUG: Not Android platform in check, returning true");
      return true;
    }

    final sdkInt = await _getAndroidSdkVersion();
    debugPrint("DEBUG: Checking permissions for Android SDK: $sdkInt");

    // For Android 10 and below
    if (sdkInt <= 29) {
      final status = await Permission.storage.status;
      debugPrint("DEBUG: Storage permission status: ${status.isGranted}");
      return status.isGranted;
    }
    // For Android 11+
    else {
      final manageStatus = await Permission.manageExternalStorage.status;
      debugPrint("DEBUG: MANAGE_EXTERNAL_STORAGE status: ${manageStatus.isGranted}");

      // For Android 11+, we mainly need MANAGE_EXTERNAL_STORAGE
      // The basic storage permission is not sufficient anyway
      return manageStatus.isGranted;
    }
  }

  static Future<int> _getAndroidSdkVersion() async {
    // Return cached value if available
    if (_cachedAndroidSdk != null) {
      return _cachedAndroidSdk!;
    }

    if (!Platform.isAndroid) return 0;

    try {
      // Use device_info_plus plugin to get accurate SDK version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _cachedAndroidSdk = androidInfo.version.sdkInt;
      debugPrint("DEBUG: Got Android SDK version from device_info: ${androidInfo.version.sdkInt}");
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint("DEBUG: Error getting Android SDK version: $e");
      // Fallback to a reasonable default
      return 29; // Assume Android 10 as fallback
    }
  }
}