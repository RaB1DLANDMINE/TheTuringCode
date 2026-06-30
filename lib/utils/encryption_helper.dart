import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  // In a real scenario, this key should be managed securely.
  // For this exercise, we use a derived key from a fixed passphrase.
  static const String _passphrase = 'secure_passphrase_123';

  static Key _deriveKey(String passphrase) {
    final keyBytes = sha256.convert(utf8.encode(passphrase)).bytes;
    return Key(Uint8List.fromList(keyBytes));
  }

  static String decrypt(Uint8List encryptedData) {
    final key = _deriveKey(_passphrase);
    // Use the first 16 bytes as IV (simple approach for this task)
    final iv = IV(Uint8List.fromList(List.filled(16, 0)));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final decrypted = encrypter.decryptBytes(Encrypted(encryptedData), iv: iv);
    return utf8.decode(decrypted);
  }

  static Uint8List encrypt(String plainText) {
    final key = _deriveKey(_passphrase);
    final iv = IV(Uint8List.fromList(List.filled(16, 0)));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.bytes;
  }
}
