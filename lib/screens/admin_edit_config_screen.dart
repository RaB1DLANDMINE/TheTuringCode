import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/config_service.dart';

class AdminEditConfigScreen extends StatefulWidget {
  const AdminEditConfigScreen({super.key});

  @override
  State<AdminEditConfigScreen> createState() => _AdminEditConfigScreenState();
}

class _AdminEditConfigScreenState extends State<AdminEditConfigScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = ConfigService.getLoadedConfig() ?? {};
    _controller.text = const JsonEncoder.withIndent('  ').convert(config);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final config = json.decode(_controller.text);
      if (config is! Map<String, dynamic>) {
        throw const FormatException('Config must be a JSON object');
      }

      final success = await ConfigService.saveConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Config saved and encrypted' : 'Failed to save config')),
        );
        if (success) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid JSON: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Config JSON'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter config JSON here...',
          ),
        ),
      ),
    );
  }
}
