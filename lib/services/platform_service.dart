import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.rab1d.debug/device_info');

  static Future<String> getWifiCountry() async {
    try {
      final String countryCode = await _channel.invokeMethod('getWifiCountry');
      return countryCode;
    } on PlatformException catch (e) {
      return "Unknown: ${e.message}";
    }
  }

  static Future<double> getChargingWattage() async {
    try {
      final double wattage = await _channel.invokeMethod('getChargingWattage');
      return wattage;
    } on PlatformException catch (e) {
      return 0.0;
    }
  }

  static Future<Map<String, dynamic>> getBatteryData() async {
    try {
      final Map<dynamic, dynamic> data = await _channel.invokeMethod('getBatteryData');
      return Map<String, dynamic>.from(data);
    } on PlatformException catch (e) {
      return {"error": e.message};
    }
  }
}
