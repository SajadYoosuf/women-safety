import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _stealthMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stealthMode = prefs.getBool('stealth_mode') ?? false;
    });
  }

  void _toggleStealth(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stealth_mode', val);
    setState(() {
      _stealthMode = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Stealth Mode"),
            subtitle: const Text("App appears as a Note Taker"),
            value: _stealthMode,
            onChanged: _toggleStealth,
          ),
          SwitchListTile(
            title: const Text("Shake Detection"),
            subtitle: const Text("Shake phone to trigger alert"),
            value: true, 
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text("Voice Detection"),
            subtitle: const Text("Listen for 'Help' or 'SOS'"),
            value: true, 
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
