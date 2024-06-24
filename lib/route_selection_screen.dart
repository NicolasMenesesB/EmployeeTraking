import 'package:flutter/material.dart';

class RouteSelectionScreen extends StatelessWidget {
  final Function(String) onSelectRoute;

  RouteSelectionScreen({required this.onSelectRoute});

  @override
  Widget build(BuildContext context) {
    // Aquí puedes implementar la lógica para cargar y mostrar las rutas disponibles
    List<String> availableRoutes = [
      'Route A',
      'Route B',
      'Route C'
    ]; // Ejemplo de rutas disponibles

    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Ruta'),
      ),
      body: ListView.builder(
        itemCount: availableRoutes.length,
        itemBuilder: (context, index) {
          final routeName = availableRoutes[index];
          return ListTile(
            title: Text(routeName),
            onTap: () {
              // Llamar a la función onSelectRoute y pasar el nombre de la ruta seleccionada
              onSelectRoute(routeName);
              Navigator.pop(context); // Regresar a la pantalla anterior
            },
          );
        },
      ),
    );
  }
}
