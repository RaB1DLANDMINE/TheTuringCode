import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/config_service.dart';
import 'package:app/utils/encryption_helper.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Config loading fallback to assets', () async {
    final config = {"codes": {"1234": "show_debug"}};
    final jsonStr = json.encode(config);
    final encryptedBytes = EncryptionHelper.encrypt(jsonStr);

    // Mock asset bundle correctly
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        // The message is the asset name as a string, but prefixed with something?
        // Actually rootBundle.load(path) just sends the path as a string encoded as UTF8.
        final Uint8List list = message!.buffer.asUint8List();
        final String key = utf8.decode(list);

        if (key == 'assets/config.bin') {
           return ByteData.view(encryptedBytes.buffer);
        }
        return null;
      },
    );

    final loadedConfig = await ConfigService.loadConfig();
    expect(loadedConfig, isNotNull);
    expect(loadedConfig!['codes']['1234'], 'show_debug');
  });
}
