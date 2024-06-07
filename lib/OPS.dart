import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OPS extends StatefulWidget {
  const OPS({super.key});

  @override
  _OPSState createState() => _OPSState();
}

class Point {
  LatLng coordinates;
  String name;
  String description;
  double radius;

  Point({
    required this.coordinates,
    required this.name,
    required this.description,
    required this.radius,
  });
}

class _OPSState extends State<OPS> {
  final List<Point> _points = [];
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  void _addPoint(LatLng point) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Point'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _radiusController,
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String name = _nameController.text.trim();
                final String description = _descriptionController.text.trim();
                final double radius =
                    double.parse(_radiusController.text.trim());
                setState(() {
                  _points.add(Point(
                    coordinates: point,
                    name: name,
                    description: description,
                    radius: radius,
                  ));
                });
                _nameController.clear();
                _descriptionController.clear();
                _radiusController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editPoint(int index) {
    final point = _points[index];
    _nameController.text = point.name;
    _descriptionController.text = point.description;
    _radiusController.text = point.radius.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Point'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _radiusController,
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  point.name = _nameController.text.trim();
                  point.description = _descriptionController.text.trim();
                  point.radius = double.parse(_radiusController.text.trim());
                });
                _nameController.clear();
                _descriptionController.clear();
                _radiusController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removePoint(int index) {
    setState(() {
      _points.removeAt(index);
    });
  }

  void _centerMap(LatLng point) {
    _mapController.move(point, _mapController.zoom);
  }

  Future<void> _searchLocation(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final location = data[0];
        final double lat = double.parse(location['lat']);
        final double lon = double.parse(location['lon']);
        final LatLng point = LatLng(lat, lon);
        _centerMap(point);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Screen with OSM'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Location',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      _searchLocation(query);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(-17.41390155045497, -66.16539789764035),
                      zoom: 13.0,
                      onTap: (tapPosition, point) {
                        _addPoint(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: _points.map((point) {
                          return Marker(
                            point: point.coordinates,
                            builder: (ctx) => const Icon(Icons.location_on,
                                color: Colors.red, size: 40.0),
                          );
                        }).toList(),
                      ),
                      CircleLayer(
                        circles: _points.map((point) {
                          return CircleMarker(
                            point: point.coordinates,
                            radius: point.radius,
                            color: Colors.blue.withOpacity(0.3),
                            borderStrokeWidth: 2.0,
                            borderColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Coordinates:'),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _points.length,
                          itemBuilder: (context, index) {
                            final point = _points[index];
                            return ListTile(
                              title: Text(
                                  '${point.name} (${point.coordinates.latitude}, ${point.coordinates.longitude})'),
                              subtitle: Text(point.description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.orange),
                                    onPressed: () {
                                      _editPoint(index);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      _removePoint(index);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.center_focus_strong,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _centerMap(point.coordinates);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
