import 'package:flutter/material.dart';
import '../services/config_service.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ConfigService.getLoadedConfig();
    final Map<String, dynamic> codes = config?['codes'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Menu - Codes')),
      body: codes.isEmpty
          ? const Center(child: Text('No codes found.'))
          : ListView.builder(
              itemCount: codes.length,
              itemBuilder: (context, index) {
                final code = codes.keys.elementAt(index);
                final action = codes[code];
                return ListTile(
                  title: Text('Code: $code', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Action: $action'),
                  leading: const Icon(Icons.vpn_key),
                );
              },
            ),
    );
  }
}
