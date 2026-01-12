import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: FutureBuilder<UserModel?>(
        future: user != null ? authService.getUser(user.uid) : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data;
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFFE0F7FA),
                  child: Icon(Icons.person, size: 60, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoTile("Name", userData?.name ?? "N/A", Icons.person_outline),
              _buildInfoTile("Phone", userData?.phone ?? "N/A", Icons.phone_outlined),
              _buildInfoTile("UID", user?.uid ?? "N/A", Icons.fingerprint),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => authService.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blueGrey),
          title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        const Divider(),
      ],
    );
  }
}
