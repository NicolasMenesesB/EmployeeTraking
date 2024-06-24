import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RoutesMgmt.dart';

class RoutesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Rutas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final routes = snapshot.data!.docs;
          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return ListTile(
                title: Text(route['name']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // Mostrar un diálogo de confirmación antes de eliminar
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Eliminar Ruta'),
                        content: Text(
                            '¿Estás seguro de que quieres eliminar esta ruta?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Cerrar el diálogo
                            },
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Eliminar la ruta de Firestore
                              FirebaseFirestore.instance
                                  .collection('routes')
                                  .doc(route.id)
                                  .delete();
                              Navigator.pop(context); // Cerrar el diálogo
                            },
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () {
                  // Navegar a la pantalla de detalles de la ruta
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //       builder: (context) =>
                  //           RouteDetailsScreen(routeId: route.id)),
                  // );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla para crear una nueva ruta
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RoutesMgmt()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
