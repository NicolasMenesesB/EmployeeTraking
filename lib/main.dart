import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Management'),
        ),
        body: const AdminForm(),
      ),
    );
  }
}

class AdminForm extends StatefulWidget {
  const AdminForm({super.key});

  @override
  _AdminFormState createState() => _AdminFormState();
}

class _AdminFormState extends State<AdminForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addAdmin(String email, String name) async {
    // Reference to the `admins` collection
    CollectionReference admins = firestore.collection('admins');

    // Create a new document with specified fields
    try {
      await admins.add({
        'email': email,
        'name': name,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding admin: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final String email = _emailController.text.trim();
              final String name = _nameController.text.trim();
              if (email.isNotEmpty && name.isNotEmpty) {
                addAdmin(email, name);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields.'),
                  ),
                );
              }
            },
            child: const Text('Add Admin'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
