import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  static const routeName = '/map';

  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  static const String _googleApiKey = 'AIzaSyC6FUq2HsQPZicGKijt1xEh4fuo_19vBb4';
  final _places = GoogleMapsPlaces(apiKey: _googleApiKey);
  LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _addMarker(_currentPosition!, 'My Location', 'This is my current location');
        _searchNearbyPlaces();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        // Handle location error
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle permission denial
    }
  }

  void _addMarker(LatLng position, String markerId, String info, {BitmapDescriptor? icon}) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: info),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: () => _launchMaps(position.latitude, position.longitude),
    );
    setState(() {
      _markers.add(marker);
    });
  }

  Future<void> _searchNearbyPlaces() async {
    if (_currentPosition == null) return;

    final location = Location(
        lat: _currentPosition!.latitude, lng: _currentPosition!.longitude);
    final result = await _places.searchNearbyWithRadius(location, 5000,
        type: 'veterinary_care|pet_store|animal_shelter');

    if (result.status == "OK") {
      for (var place in result.results) {
        final placeLoc = place.geometry!.location;
        final lat = placeLoc.lat;
        final lng = placeLoc.lng;
        final name = place.name;

        _addMarker(LatLng(lat, lng), place.placeId, name,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pet Services'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? const Center(child: Text('Could not get current location.'))
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);},
                  markers: _markers,
                ),
    );
  }
}