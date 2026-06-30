import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/encryption_helper.dart';

void main() {
  test('Encryption/Decryption Test', () {
    const plainText = '{"test": "data"}';
    final encrypted = EncryptionHelper.encrypt(plainText);
    final decrypted = EncryptionHelper.decrypt(encrypted);

    expect(decrypted, plainText);
  });
}
