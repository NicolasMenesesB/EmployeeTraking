import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutesMgmt extends StatefulWidget {
  const RoutesMgmt({Key? key}) : super(key: key);

  @override
  _RoutesManagementScreenState createState() => _RoutesManagementScreenState();
}

class _RoutesManagementScreenState extends State<RoutesMgmt> {
  List<Point> _points = []; // Lista de puntos disponibles
  List<String> _selectedPointIds =
      []; // Lista de IDs de puntos seleccionados para la nueva ruta
  String _routeName = ''; // Nombre de la nueva ruta

  @override
  void initState() {
    super.initState();
    _loadPointsFromFirebase(); // Cargar puntos al iniciar la pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Nueva Ruta'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _points.length,
              itemBuilder: (context, index) {
                final point = _points[index];
                return ListTile(
                  title: Text(point.name),
                  subtitle: Text(point.description),
                  trailing: _selectedPointIds.contains(point.docId ?? '')
                      ? Icon(Icons.check)
                      : null,
                  onTap: () {
                    _togglePointSelection(point);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Nombre de la Ruta',
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _routeName = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _saveRoute(); // Guardar la nueva ruta
                  },
                  child: Text('Guardar Ruta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _loadPointsFromFirebase() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('points').get();

      setState(() {
        _points.clear();
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final point = Point.fromMap(data, id: doc.id);
          _points.add(point);
        }
      });
    } catch (error) {
      print('Error loading points: $error');
      // Maneja el error según sea necesario
    }
  }

  void _togglePointSelection(Point point) {
    setState(() {
      if (_selectedPointIds.contains(point.docId ?? '')) {
        _selectedPointIds.remove(point.docId ?? '');
      } else {
        _selectedPointIds.add(point.docId ?? '');
      }
    });
  }

  void _saveRoute() async {
    try {
      // Validar que se haya ingresado un nombre para la ruta
      if (_routeName.isEmpty) {
        print('Error: Debes ingresar un nombre para la ruta.');
        return;
      }

      // Crear un nuevo documento para la ruta en Firestore
      final routeRef = FirebaseFirestore.instance.collection('routes').doc();

      // Obtener el ID del documento recién creado
      final routeId = routeRef.id;

      // Guardar la ruta con el nombre y los IDs de los puntos seleccionados
      await routeRef.set({
        'name': _routeName,
        'pointIds': _selectedPointIds,
      });

      // Limpiar los puntos seleccionados y el nombre de la ruta después de guardar
      setState(() {
        _selectedPointIds.clear();
        _routeName = '';
      });

      // Confirmación en consola
      print('Ruta guardada con éxito: ID $routeId');
    } catch (error) {
      print('Error al guardar la ruta: $error');
      // Maneja el error según sea necesario
    }
  }
}

class Point {
  final String docId;
  final String name;
  final String description;

  Point({
    required this.docId,
    required this.name,
    required this.description,
  });

  factory Point.fromMap(Map<String, dynamic> map, {required String id}) {
    return Point(
      docId: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
