import 'package:flutter/material.dart';
import 'widgets/keypad_widget.dart';
import 'services/config_service.dart';
import 'screens/charger_wait_screen.dart';
import 'screens/debug_data_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug Tool',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const KeypadScreen(),
    );
  }
}

class KeypadScreen extends StatefulWidget {
  const KeypadScreen({super.key});

  @override
  State<KeypadScreen> createState() => _KeypadScreenState();
}

class _KeypadScreenState extends State<KeypadScreen> {
  String _enteredCode = "";
  Map<String, dynamic>? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await ConfigService.loadConfig();
    setState(() {
      _config = config;
    });
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == '#') {
        _checkCode();
      } else if (key == '*') {
        _enteredCode = "";
      } else {
        _enteredCode += key;
      }
    });
  }

  void _checkCode() {
    if (_config != null && _config!['codes'] != null) {
      final codes = _config!['codes'] as Map<String, dynamic>;
      if (codes.containsKey(_enteredCode)) {
        final action = codes[_enteredCode];
        if (action == 'show_debug') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChargerWaitScreen(
                onComplete: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const DebugDataScreen()),
                  );
                },
              ),
            ),
          );
          return;
        }
      }
    }

    // Reset if wrong or no config
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid Code'), duration: Duration(seconds: 1)),
    );
    setState(() {
      _enteredCode = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Code')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              _enteredCode.isEmpty ? "---" : _enteredCode,
              style: const TextStyle(fontSize: 32, letterSpacing: 8),
            ),
          ),
          const Spacer(),
          KeypadWidget(onKeyPressed: _onKeyPressed),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
