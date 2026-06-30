import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

class ChargerWaitScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ChargerWaitScreen({super.key, required this.onComplete});

  @override
  State<ChargerWaitScreen> createState() => _ChargerWaitScreenState();
}

class _ChargerWaitScreenState extends State<ChargerWaitScreen> {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _subscription;
  bool _isCharging = false;
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
    _subscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
      if (state == BatteryState.charging || state == BatteryState.full) {
        if (!_isCharging) {
          _startCountdown();
        }
      } else {
        _stopCountdown();
      }
    });
  }

  Future<void> _checkInitialState() async {
    final state = await _battery.batteryState;
    if (state == BatteryState.charging || state == BatteryState.full) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() {
      _isCharging = true;
      _countdown = 5;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          widget.onComplete();
        }
      });
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    setState(() {
      _isCharging = false;
      _countdown = 5;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              _isCharging ? 'Charger connected!' : 'Plug in OEM charger',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_isCharging)
              Text(
                'Updating data in $_countdown seconds...',
                style: const TextStyle(fontSize: 18),
              )
            else
              const Text(
                'Waiting for charger...',
                style: TextStyle(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }
}
