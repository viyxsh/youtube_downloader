import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    if (Platform.isAndroid && await Permission.manageExternalStorage.status.isDenied) {
      await Permission.manageExternalStorage.request();
    }

    return status.isGranted;
  }
}