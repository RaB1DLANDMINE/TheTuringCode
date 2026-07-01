import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/platform_service.dart';
import '../services/config_service.dart';

class DebugDataScreen extends StatefulWidget {
  const DebugDataScreen({super.key});

  @override
  State<DebugDataScreen> createState() => _DebugDataScreenState();
}

class _DebugDataScreenState extends State<DebugDataScreen> {
  String _deviceName = "Loading...";
  String _deviceModel = "Loading...";
  String _dateTime = "";
  String _wifiCountry = "Loading...";
  String _jumble = "";
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await [
      Permission.location,
      Permission.phone,
    ].request();

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final wifiCountry = await PlatformService.getWifiCountry();
    final batteryData = await PlatformService.getBatteryData();

    final config = ConfigService.getLoadedConfig() ?? {};

    final double voltageMv = (batteryData['voltage_mv'] ?? 0).toDouble();
    final double voltageV1Mv = (batteryData['voltage_v1_mv'] ?? 0).toDouble();
    final double currentRaw = (batteryData['current_raw'] ?? 0).toDouble().abs();
    final bool isDual = batteryData['is_dual'] ?? false;
    final String manufacturer = (batteryData['manufacturer'] ?? "").toString();
    final String brand = (batteryData['brand'] ?? "").toString();

    // Normalization logic for current
    double currentAmps = currentRaw / 1000000.0;
    if (currentAmps > 0 && currentAmps < 0.05) {
      currentAmps = currentRaw / 1000.0;
    }

    // Logic from PlusPlusBattery: if dual cell, voltage is sum of cells
    double totalVoltageV;
    if (isDual && voltageV1Mv > 0) {
      totalVoltageV = (voltageMv + voltageV1Mv) / 1000.0;
    } else {
      // Automatic 2x multiplier for OPlus if only one voltage was read but it's dual cell
      bool suspectedDual = isDual ||
                           manufacturer.contains("oneplus") || brand.contains("oneplus") ||
                           manufacturer.contains("oppo") || brand.contains("oppo");

      double multiplier = config['voltage_multiplier']?.toDouble() ?? (suspectedDual ? 2.0 : 1.0);
      totalVoltageV = (voltageMv / 1000.0) * multiplier;
    }

    final double finalCurrent = currentAmps * (config['current_multiplier']?.toDouble() ?? 1.0);
    final double wattage = totalVoltageV * finalCurrent;

    final jumble = _generateJumble(
      wattage.toStringAsFixed(2),
      totalVoltageV.toStringAsFixed(2),
      finalCurrent.toStringAsFixed(3),
      (voltageMv / 1000.0).toStringAsFixed(2), // Single cell raw
    );

    setState(() {
      _deviceName = androidInfo.device;
      _deviceModel = androidInfo.model;
      _dateTime = formattedDate;
      _wifiCountry = wifiCountry;
      _jumble = jumble;
      _loaded = true;
    });
  }

  String _generateJumble(String wattage, String voltage, String current, String rawVoltage) {
    final random = Random();
    const characters = '0123456789';
    List<String> base = List.generate(64, (_) => characters[random.nextInt(characters.length)]);

    _insertAt(base, 20, wattage);
    _insertAt(base, 30, voltage);
    _insertAt(base, 40, current);
    _insertAt(base, 50, rawVoltage);

    return base.join('');
  }

  void _insertAt(List<String> base, int index, String value) {
    for (int i = 0; i < value.length; i++) {
      if (index + i < base.length) {
        base[index + i] = value[i];
      }
    }
  }

  void _copyToClipboard() {
    final text = "Device: $_deviceName\n"
                 "Model: $_deviceModel\n"
                 "Time: $_dateTime\n"
                 "WiFi Country: $_wifiCountry\n\n"
                 "Jumble: $_jumble";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Debug Data', style: TextStyle(color: Colors.greenAccent)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.greenAccent),
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _debugLine("Device: $_deviceName"),
                _debugLine("Model: $_deviceModel"),
                _debugLine("Time: $_dateTime"),
                _debugLine("WiFi Country: $_wifiCountry"),
                const SizedBox(height: 20),
                _debugLine(_jumble, isJumble: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _debugLine(String text, {bool isJumble = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'monospace',
          fontSize: isJumble ? 14 : 16,
        ),
      ),
    );
  }
}
