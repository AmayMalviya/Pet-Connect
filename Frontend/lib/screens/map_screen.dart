import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static const String routeName = '/map-screen';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  latlong2.LatLng? _currentLocation;
  bool _isLoading = true;
  String? _error;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Location services are disabled.';
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied';
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Location permissions are permanently denied, we cannot request permissions.';
        _isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = latlong2.LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _fetchNearbyPlaces(latlong2.LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        _error = 'Failed to get current location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyPlaces(latlong2.LatLng location) async {
    final String apiKey = 'AIzaSyAAprcPivvOxN-w7XNsAHOiVydUcxjXdHI';
    final String baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
    final String types = 'veterinary_care|pet_store|animal_shelter'; // Add more types as needed
    final String keywords = 'pet services|pet adoption';

    final Uri uri = Uri.parse(
        '$baseUrl?location=${location.latitude},${location.longitude}&radius=5000&type=$types&keyword=$keywords&key=$apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            for (var place in data['results']) {
              final lat = place['geometry']['location']['lat'];
              final lng = place['geometry']['location']['lng'];
              final name = place['name'];
              final placeId = place['place_id'];

              _markers.add(
                Marker(
                  point: latlong2.LatLng(lat, lng),
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 30.0),
                ),
              );
            }
          });
        } else {
          print('Google Places API error: ${data['status']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
    }
  }

  void _onMapCreated(MapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Services', style: GoogleFonts.poppins()),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _currentLocation == null
                  ? const Center(child: Text('Could not get current location.'))
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 14.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.pet_connect_app',
                        ),
                        MarkerLayer(
                          markers: _markers,
                        ),
                      ],
                    ),
    );
  }
}
