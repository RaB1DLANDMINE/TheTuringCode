import 'package:flutter/material.dart';
import '../services/config_service.dart';
import 'admin_edit_config_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final config = ConfigService.getLoadedConfig();
    final Map<String, dynamic> codes = config?['codes'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Menu - Codes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AdminEditConfigScreen()),
              );
              if (updated == true) {
                setState(() {}); // Refresh list
              }
            },
          ),
        ],
      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final updated = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AdminEditConfigScreen()),
          );
          if (updated == true) {
            setState(() {}); // Refresh list
          }
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
