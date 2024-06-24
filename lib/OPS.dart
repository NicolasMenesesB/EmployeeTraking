import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OPS extends StatefulWidget {
  const OPS({super.key});

  @override
  _OPSState createState() => _OPSState();
}

class Point {
  final LatLng coordinates;
  final String name;
  final String description;
  final double radius;
  String? docId;

  Point({
    required this.coordinates,
    required this.name,
    required this.description,
    required this.radius,
    this.docId,
  });

  Map<String, dynamic> toMap() {
    return {
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'name': name,
      'description': description,
      'radius': radius,
    };
  }

  factory Point.fromMap(Map<String, dynamic> map, {String? id}) {
    return Point(
      coordinates: LatLng(map['coordinates']['latitude'] as double,
          map['coordinates']['longitude'] as double),
      name: map['name'] as String,
      description: map['description'] as String,
      radius: map['radius'] as double,
      docId: id,
    );
  }
}

class _OPSState extends State<OPS> {
  final List<Point> _points = [];
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPointsFromFirebase();
  }

  Future<void> _loadPointsFromFirebase() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('points').get();

      setState(() {
        _points.clear();
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Ensure coordinates data is present and of the correct type
          if (data.containsKey('coordinates') &&
              data['coordinates'] is Map<String, dynamic>) {
            final coordinatesData = data['coordinates'] as Map<String, dynamic>;
            final latitude = coordinatesData['latitude'];
            final longitude = coordinatesData['longitude'];

            // Ensure latitude and longitude are of type double and within valid range
            if (latitude is double &&
                longitude is double &&
                latitude >= -90 &&
                latitude <= 90 &&
                longitude >= -180 &&
                longitude <= 180) {
              final coordinates = LatLng(latitude, longitude);
              final point = Point(
                coordinates: coordinates,
                name: data['name'] as String,
                description: data['description'] as String,
                radius: data['radius'] as double,
                docId: doc.id,
              );
              _points.add(point);
            } else {
              print('Error: Latitude or Longitude is not within valid range.');
            }
          } else {
            print(
                'Error: Coordinates data is missing or not in the expected format.');
          }
        }
      });
    } catch (error) {
      print('Error fetching points: $error');
      // Handle error as needed
    }
  }

  Future<void> _savePointToFirebase(Point point) async {
    await FirebaseFirestore.instance.collection('points').add(point.toMap());
  }

  Future<void> _updatePointInFirebase(String docId, Point point) async {
    await FirebaseFirestore.instance
        .collection('points')
        .doc(docId)
        .update(point.toMap());
  }

  Future<void> _deletePointFromFirebase(String docId) async {
    await FirebaseFirestore.instance.collection('points').doc(docId).delete();
  }

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
                final newPoint = Point(
                  coordinates: point,
                  name: name,
                  description: description,
                  radius: radius,
                );
                setState(() {
                  _points.add(newPoint);
                });
                _savePointToFirebase(newPoint);
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
    TextEditingController nameController =
        TextEditingController(text: point.name);
    TextEditingController descriptionController =
        TextEditingController(text: point.description);
    TextEditingController radiusController =
        TextEditingController(text: point.radius.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Point'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(labelText: 'Radius'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _points[index] = Point(
                    coordinates: point.coordinates,
                    name: nameController.text,
                    description: descriptionController.text,
                    radius: double.parse(radiusController.text),
                    docId: point.docId,
                  );
                });
                if (point.docId != null) {
                  await FirebaseFirestore.instance
                      .collection('points')
                      .doc(point.docId!)
                      .update({
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'radius': double.parse(radiusController.text),
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removePoint(int index) async {
    final point = _points[index];
    if (point.docId != null) {
      await FirebaseFirestore.instance
          .collection('points')
          .doc(point.docId!)
          .delete();
    }
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
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
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
                        child: Text('Coordenadas:'),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _points.length,
                          itemBuilder: (context, index) {
                            final point = _points[index];
                            final docId =
                                ''; // You need to fetch the document ID
                            return ListTile(
                              title: Text(
                                  '(${point.coordinates.latitude}, ${point.coordinates.longitude})'),
                              subtitle: Text(
                                  'Name: ${point.name}\nDescription: ${point.description}\nRadius: ${point.radius} meters'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
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
