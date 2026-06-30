# Debug Keypad App

A specialized Flutter Android application for hardware debugging and diagnostics.

## Features
- **Telephone Keypad Interface**: Enter activation codes to trigger debug screens.
- **Encrypted Configuration**: Codes and actions are stored in an AES-256-CBC encrypted file.
- **Dynamic Updates**: Support for updating the configuration via an external file.
- **Hardware Capturing**: Capture device info, location-based country, and precise charging wattage.
- **Admin Mode**: Access a hidden menu to view all decrypted codes.

## Key File Paths

### Configuration Files
- **Bundled Config**: `assets/config.bin`
  - Encrypted configuration file included in the app package.
- **External Updatable Config**: `/storage/emulated/0/Download/app_config.bin`
  - The app will prioritize this file if it exists in the device's Downloads folder.
- **Config Generation Tool**: `tool/generate_config.dart`
  - Use this Dart tool to encrypt a JSON configuration into the binary format.

### Admin Mode
- **Admin Unlock File**: `/storage/emulated/0/Download/.admin_unlock`
  - Placing an empty file with this name in the device's Downloads folder will enable the Admin button on the keypad screen.
  - Alternatively, the file can be placed in the app's internal documents directory.

### Native Integration
- **Android Native Code**: `android/app/src/main/kotlin/com/rab1d.debug/MainActivity.kt`
  - Handles the `MethodChannel` for fetching hardware details.

### CI/CD
- **GitHub Workflow**: `.github/workflows/build.yml`
  - Automates the build process, generating a signed APK and uploading it as an artifact.

## How to use
1. Build the app using `flutter build apk --release`.
2. Install the APK on an Android device.
3. To update codes without reinstalling:
   - Generate a new `app_config.bin` using the tool.
   - Place it in the `Download` folder of the device.
4. To enable Admin mode:
   - Create an empty `.admin_unlock` file in the `Download` folder of the device.
   - Restart the app. An admin icon will appear in the top-right corner.
