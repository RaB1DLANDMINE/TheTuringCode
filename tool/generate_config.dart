import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class EncryptionTool {
  static const String _passphrase = 'secure_passphrase_123';

  static Key _deriveKey(String passphrase) {
    final keyBytes = sha256.convert(utf8.encode(passphrase)).bytes;
    return Key(Uint8List.fromList(keyBytes));
  }

  static Uint8List encrypt(String plainText) {
    final key = _deriveKey(_passphrase);
    final iv = IV(Uint8List.fromList(List.filled(16, 0)));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.bytes;
  }
}

void main() {
  final config = {
    "codes": {
      "1234": "show_debug"
    },
    "voltage_multiplier": 2.0,
    "current_multiplier": 1.0
  };

  final jsonStr = json.encode(config);
  final encryptedBytes = EncryptionTool.encrypt(jsonStr);

  File('assets/config.bin').writeAsBytesSync(encryptedBytes);
  print('Generated assets/config.bin with default OnePlus multipliers (voltage_multiplier: 2.0)');
}
