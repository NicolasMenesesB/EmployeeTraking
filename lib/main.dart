import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      title: 'Admin Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/admin_home': (context) => AdminHomeScreen(),
        '/register_admin': (context) => RegisterAdminScreen(),
        '/register_employee': (context) => RegisterEmployeeScreen(),
        '/employee_home': (context) => EmployeeHomeScreen(),
        '/admin_list': (context) => AdminListScreen(),
        '/employee_list': (context) => EmployeeListScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
        if (adminDoc.exists) {
          Navigator.pushNamed(context, '/admin_home', arguments: adminDoc.data());
        } else {
          DocumentSnapshot employeeDoc = await FirebaseFirestore.instance.collection('employees').doc(user.uid).get();
          if (employeeDoc.exists) {
            Navigator.pushNamed(context, '/employee_home', arguments: employeeDoc.data());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No admin or employee found for this user.')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido',
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Iniciar Sesión',
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Administradores'),
        actions: [
          if (userData != null && userData['photoUrl'] != null)
            CircleAvatar(
              backgroundImage: NetworkImage(userData['photoUrl']),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userData != null && userData['photoUrl'] != null)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(userData['photoUrl']),
                    ),
                  SizedBox(height: 10),
                  Text(
                    'Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_add_alt_1),
              title: Text('Registrar Empleado'),
              onTap: () {
                Navigator.pushNamed(context, '/register_employee');
              },
            ),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('Ver Empleados'),
              onTap: () {
                Navigator.pushNamed(context, '/employee_list');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido, ${userData?['name']}!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Seleccione una opción del menú para continuar.',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class RegisterAdminScreen extends StatefulWidget {
  @override
  _RegisterAdminScreenState createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  String _gender = 'M';
  String _photoUrl = '';

  Future<void> _uploadImage() async {
    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((e) async {
            final filePath = 'images/${files[0].name}';
            final storageRef = _storage.ref().child(filePath);
            final uploadTask = storageRef.putBlob(files[0]);
            final snapshot = await uploadTask.whenComplete(() {});
            final downloadUrl = await snapshot.ref.getDownloadURL();
            setState(() {
              _photoUrl = downloadUrl;
            });
          });
        }
      });
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        File file = File(image.path);
        try {
          final storageRef = _storage.ref().child('images/${file.path.split('/').last}');
          final uploadTask = storageRef.putFile(file);
          final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
          final String downloadUrl = await snapshot.ref.getDownloadURL();
          setState(() {
            _photoUrl = downloadUrl;
          });
        } catch (e) {
          print('Error: $e');
        }
      }
    }
  }

  Future<void> _register() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('admins').doc(user.uid).set({
          'email': _emailController.text,
          'name': _nameController.text,
          'lastName': _lastNameController.text,
          'gender': _gender,
          'dateOfBirth': Timestamp.fromDate(DateTime.parse(_dateOfBirthController.text)),
          'photoUrl': _photoUrl,
        });
        Navigator.pushNamed(context, '/admin_list');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Administrador')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Apellido'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _gender,
                items: [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Género'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _dateOfBirthController,
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dateOfBirthController.text = pickedDate.toIso8601String().split('T').first;
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Subir Foto'),
              ),
              _photoUrl.isNotEmpty
                  ? Image.network(_photoUrl, height: 100)
                  : Container(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class RegisterEmployeeScreen extends StatefulWidget {
  @override
  _RegisterEmployeeScreenState createState() => _RegisterEmployeeScreenState();
}

class _RegisterEmployeeScreenState extends State<RegisterEmployeeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _assignedRoutesController = TextEditingController();
  bool _active = true;
  String _gender = 'M';
  String _photoUrl = '';

  Future<void> _uploadImage() async {
    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((e) async {
            final filePath = 'images/${files[0].name}';
            final storageRef = _storage.ref().child(filePath);
            final uploadTask = storageRef.putBlob(files[0]);
            final snapshot = await uploadTask.whenComplete(() {});
            final downloadUrl = await snapshot.ref.getDownloadURL();
            setState(() {
              _photoUrl = downloadUrl;
            });
          });
        }
      });
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        File file = File(image.path);
        try {
          final storageRef = _storage.ref().child('images/${file.path.split('/').last}');
          final uploadTask = storageRef.putFile(file);
          final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
          final String downloadUrl = await snapshot.ref.getDownloadURL();
          setState(() {
            _photoUrl = downloadUrl;
          });
        } catch (e) {
          print('Error: $e');
        }
      }
    }
  }

  Future<void> _register() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('employees').doc(user.uid).set({
          'email': _emailController.text,
          'name': _nameController.text,
          'lastName': _lastNameController.text,
          'gender': _gender,
          'dateOfBirth': Timestamp.fromDate(DateTime.parse(_dateOfBirthController.text)),
          'photoUrl': _photoUrl,
          'assignedRoutes': _assignedRoutesController.text.split(',').map((e) => e.trim()).toList(),
          'active': _active,
        });
        Navigator.pushNamed(context, '/employee_list');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Empleado')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Apellido'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _gender,
                items: [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Género'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _dateOfBirthController,
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dateOfBirthController.text = pickedDate.toIso8601String().split('T').first;
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _assignedRoutesController,
                decoration: InputDecoration(labelText: 'Rutas Asignadas (separadas por comas)'),
              ),
              SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Activo'),
                value: _active,
                onChanged: (bool value) {
                  setState(() {
                    _active = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Subir Foto'),
              ),
              _photoUrl.isNotEmpty
                  ? Image.network(_photoUrl, height: 100)
                  : Container(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class EmployeeHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Home'),
        actions: [
          if (userData != null && userData['photoUrl'] != null)
            CircleAvatar(
              backgroundImage: NetworkImage(userData['photoUrl']),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userData != null && userData['photoUrl'] != null)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(userData['photoUrl']),
                    ),
                  SizedBox(height: 10),
                  Text(
                    'Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                // Lógica para cerrar sesión
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userData != null)
              Text(
                '¡Bienvenido, ${userData['name']}!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Seleccione una opción del menú para continuar.',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class AdminListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Administradores')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admins').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final admins = snapshot.data!.docs;
          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              return ListTile(
                title: Text(admin['name']),
                subtitle: Text(admin['email']),
              );
            },
          );
        },
      ),
    );
  }
}

class EmployeeListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Empleados')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final employees = snapshot.data!.docs;
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return ListTile(
                title: Text(employee['name']),
                subtitle: Text(employee['email']),
              );
            },
          );
        },
      ),
    );
  }
}
