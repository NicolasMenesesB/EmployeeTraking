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

class _OPSState extends State<OPS> {
  final List<LatLng> _points = [];
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  void _addPoint(LatLng point) {
    setState(() {
      _points.add(point);
    });
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
                      center: LatLng(-17.41390155045497,
                          -66.16539789764035), // Coordenadas iniciales
                      zoom: 13.0, // Nivel de zoom inicial
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
                            point: point,
                            builder: (ctx) => const Icon(Icons.location_on,
                                color: Colors.red, size: 40.0),
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
                            return ListTile(
                              title: Text(
                                  '(${point.latitude}, ${point.longitude})'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                      _centerMap(point);
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
