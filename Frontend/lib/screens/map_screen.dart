import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  static const routeName = '/map';
  final String? placeType;

  const MapScreen({super.key, this.placeType});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  static const String _googleApiKey = 'AIzaSyC6FUq2HsQPZicGKijt1xEh4fuo_19vBb4';
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _selectedPlaceType = 'veterinary_care';

  @override
  void initState() {
    super.initState();
    _selectedPlaceType = widget.placeType ?? 'veterinary_care';
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    _currentPosition = const LatLng(22.719568, 75.857727); // Indore, MP, India
    setState(() {
      _isLoading = false;
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
    _searchNearbyPlaces();
  }

  void _addMarker(LatLng position, String markerId, String info, {BitmapDescriptor? icon}) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: info),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(info),
            content: const Text('Do you want to open this location in Google Maps?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _launchMaps(position.latitude, position.longitude);
                  Navigator.of(context).pop();
                },
                child: const Text('Open'),
              ),
            ],
          ),
        );
      },
    );
    setState(() {
      _markers.add(marker);
    });
  }

  Future<void> _searchNearbyPlaces({String? type, String? keyword}) async {
    if (_currentPosition == null) return;

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value != 'currentLocation');
    });

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    const radius = 5000;
    var url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=$radius&key=$_googleApiKey';

    if (type != null) {
      url += '&type=$type';
    }
    if (keyword != null) {
      url += '&keyword=$keyword';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        for (var place in data['results']) {
          final placeLoc = place['geometry']['location'];
          final lat = placeLoc['lat'];
          final lng = placeLoc['lng'];
          final name = place['name'];
          final placeId = place['place_id'];

          _addMarker(LatLng(lat, lng), placeId, name,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure));
        }
      }
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _onFilterChanged(String filter) async {
    if (filter == 'shelter') {
      final keywords = [
        'animal shelter',
        'pet adoption center',
        'dog shelter',
        'cat rescue',
        'humane society',
        'SPCA'
      ];
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value != 'currentLocation');
      });
      for (String keyword in keywords) {
        await _searchNearbyPlaces(keyword: keyword);
      }
    } else {
      _searchNearbyPlaces(type: filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pet Services'),
      ),
      body: _isLoading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  markers: _markers,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: SizedBox(
                      height: 50.0,
                      child: IntrinsicWidth(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ActionChip(
                              label: const Text('Vets'),
                              onPressed: () => _onFilterChanged('veterinary_care'),
                            ),
                            const SizedBox(width: 10),
                            ActionChip(
                              label: const Text('Pet Shops'),
                              onPressed: () => _onFilterChanged('pet_store'),
                            ),
                            const SizedBox(width: 10),
                            ActionChip(
                              label: const Text('Shelters'),
                              onPressed: () => _onFilterChanged('shelter'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              final controller = await _controller.future;
              controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
            },
            heroTag: "centerLocation",
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () async {
              final controller = await _controller.future;
              controller.animateCamera(CameraUpdate.zoomIn());
            },
            heroTag: "zoomIn",
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () async {
              final controller = await _controller.future;
              controller.animateCamera(CameraUpdate.zoomOut());
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
