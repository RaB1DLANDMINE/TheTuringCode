import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/config_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProvider();
  });

  test('Admin Mode Detection Test', () async {
    final adminFile = File('./.admin_unlock');

    // Ensure clean state
    if (await adminFile.exists()) await adminFile.delete();
    expect(await ConfigService.isAdminModeEnabled(), isFalse);

    // Create admin file
    await adminFile.create();
    expect(await ConfigService.isAdminModeEnabled(), isTrue);

    // Cleanup
    await adminFile.delete();
  });
}
