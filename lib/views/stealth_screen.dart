import 'package:flutter/material.dart';

class StealthScreen extends StatefulWidget {
  const StealthScreen({super.key});

  @override
  State<StealthScreen> createState() => _StealthScreenState();
}

class _StealthScreenState extends State<StealthScreen> {
  final TextEditingController _noteController = TextEditingController();

  void _checkSecretEntrance(String text) async {
    // Secret code: "admin" or long pressing the title
    if (text.trim().toLowerCase() == 'open safestep') {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onLongPress: () => Navigator.pushReplacementNamed(context, '/home'),
          child: const Text("My Notes", style: TextStyle(color: Colors.black87)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Start writing...",
                  border: InputBorder.none,
                ),
                onChanged: _checkSecretEntrance,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note saved locally")),
          );
        },
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.check),
      ),
    );
  }
}
