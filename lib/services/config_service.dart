import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/encryption_helper.dart';

class ConfigService {
  static const String _assetPath = 'assets/config.bin';
  static const String _fileName = 'app_config.bin';
  static const String _adminFileName = '.admin_unlock';

  static Map<String, dynamic>? _cachedConfig;

  static Future<Map<String, dynamic>?> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig;

    try {
      // 1. Try to load from external storage (Downloads)
      final externalFile = await _getExternalFile();
      if (externalFile != null && await externalFile.exists()) {
        final bytes = await externalFile.readAsBytes();
        final decrypted = EncryptionHelper.decrypt(bytes);
        _cachedConfig = json.decode(decrypted);
        return _cachedConfig;
      }

      // 2. Fallback to assets
      final assetBytes = await rootBundle.load(_assetPath);
      final decrypted = EncryptionHelper.decrypt(assetBytes.buffer.asUint8List());
      _cachedConfig = json.decode(decrypted);
      return _cachedConfig;
    } catch (e) {
      print('Error loading config: $e');
      return null;
    }
  }

  static Future<bool> isAdminModeEnabled() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final adminFile = File('${directory.path}/$_adminFileName');
      return await adminFile.exists();
    } catch (e) {
      return false;
    }
  }

  static Map<String, dynamic>? getLoadedConfig() {
    return _cachedConfig;
  }

  static Future<File?> _getExternalFile() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted ||
          await Permission.storage.request().isGranted) {
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return File('${directory.path}/$_fileName');
        }
      }
    }
    return null;
  }
}
