import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsDetailPage extends StatefulWidget {
  const ContactsDetailPage({super.key});

  @override
  State<ContactsDetailPage> createState() => _ContactsDetailPageState();
}

class _ContactsDetailPageState extends State<ContactsDetailPage> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (await Permission.contacts.request().isGranted) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone Book Sync"),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty 
              ? const Center(child: Text("No contacts found or permission denied"))
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : "No number";
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(contact.displayName[0]),
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(phone),
                    );
                  },
                ),
    );
  }
}
