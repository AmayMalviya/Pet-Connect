import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pet_connect_app/models/place.dart';
import 'package:pet_connect_app/services/place_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/widgets/place_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  static const routeName = '/map';
  final String? placeType;

  const MapScreen({super.key, this.placeType});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// ── Filter type enum ──────────────────────────────────────────────────────────

enum _PlaceFilter {
  vets('vets', '🏥 Veterinary'),
  petShops('petShops', '🛍️ Pet Shops'),
  shelters('shelters', '🏠 Shelters & NGOs'),
  all('all', '🐾 All Services');

  const _PlaceFilter(this.key, this.label);
  final String key;
  final String label;

  static _PlaceFilter fromKey(String key) =>
      _PlaceFilter.values.firstWhere((f) => f.key == key, orElse: () => vets);
}

// ── Colour per filter ─────────────────────────────────────────────────────────

Color _markerColor(_PlaceFilter filter) {
  switch (filter) {
    case _PlaceFilter.vets:
      return Colors.blue.shade600;
    case _PlaceFilter.petShops:
      return Colors.orange.shade600;
    case _PlaceFilter.shelters:
      return Colors.green.shade600;
    case _PlaceFilter.all:
      return Colors.purple.shade600;
  }
}

// ── Screen state ──────────────────────────────────────────────────────────────

class _MapScreenState extends State<MapScreen> {
  // ── API key (replace placeholder with dart-define or .env) ─────────────────
  static String get _googleApiKey {
    try {
      final envVal = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (envVal.isNotEmpty) return envVal;
    } catch (_) {}
    return const String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  }

  late final PlaceService _placeService;
  final MapController _mapController = MapController();

  // ── State ─────────────────────────────────────────────────────────────────
  LatLng _currentPosition = const LatLng(22.719568, 75.857727); // Indore default
  bool _isLocating = true;
  bool _isSearching = false;
  String? _errorMessage;
  _PlaceFilter _activeFilter = _PlaceFilter.vets;

  /// All places returned for the current filter
  List<Place> _places = [];

  @override
  void initState() {
    super.initState();
    _placeService = PlaceService(apiKey: _googleApiKey);
    _activeFilter = _PlaceFilter.fromKey(widget.placeType ?? 'vets');
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLocating = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      
      final lat = position.latitude.isNaN ? 22.719568 : position.latitude;
      final lng = position.longitude.isNaN ? 75.857727 : position.longitude;

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(lat, lng);
          _isLocating = false;
        });
      }
      await _search(_activeFilter);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not get location';
          _isLocating = false;
        });
      }
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<void> _search(_PlaceFilter filter) async {
    if (_googleApiKey.isEmpty) {
      setState(() {
        _errorMessage =
            'GOOGLE_PLACES_API_KEY is not set.\n\n'
            'Add it to your .env file:\n'
            'GOOGLE_PLACES_API_KEY=YOUR_KEY_HERE\n\n'
            'or pass via dart-define:\n'
            '--dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _places = [];
    });

    try {
      final lat = _currentPosition.latitude;
      final lng = _currentPosition.longitude;

      List<Place> results;
      switch (filter) {
        case _PlaceFilter.vets:
          results = await _placeService.searchVets(lat: lat, lng: lng);
        case _PlaceFilter.petShops:
          results = await _placeService.searchPetShops(lat: lat, lng: lng);
        case _PlaceFilter.shelters:
          results =
              await _placeService.searchSheltersAndNGOs(lat: lat, lng: lng);
        case _PlaceFilter.all:
          results = await _placeService.searchAll(lat: lat, lng: lng);
      }

      if (!mounted) return;
      setState(() {
        _places = results;
        _isSearching = false;
        if (results.isEmpty) {
          _errorMessage = 'No results found nearby. Try expanding your area.';
        }
      });
    } on PlaceServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = e.userMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  // ── Markers ────────────────────────────────────────────────────────────────

  List<Marker> get _markers {
    final markers = <Marker>[
      // Current location pin
      Marker(
        point: _currentPosition,
        width: 48,
        height: 48,
        child: _Pin(
          color: Colors.red,
          icon: Icons.my_location,
          label: 'You',
          onTap: () {},
        ),
      ),
    ];

    for (final place in _places) {
      if (place.latitude.isNaN || place.longitude.isNaN) continue;
      final point = LatLng(place.latitude, place.longitude);
      markers.add(
        Marker(
          point: point,
          width: 44,
          height: 44,
          child: _Pin(
            color: _markerColor(_activeFilter),
            icon: _iconForFilter(_activeFilter),
            label: place.displayName,
            onTap: () => _showPlaceSheet(place),
          ),
        ),
      );
    }

    return markers;
  }

  IconData _iconForFilter(_PlaceFilter f) {
    switch (f) {
      case _PlaceFilter.vets:
        return Icons.local_hospital_outlined;
      case _PlaceFilter.petShops:
        return Icons.storefront_outlined;
      case _PlaceFilter.shelters:
        return Icons.pets;
      case _PlaceFilter.all:
        return Icons.place;
    }
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showPlaceSheet(Place place) {
    final photoUrl = place.photoName != null 
        ? _placeService.getPhotoUrl(place.photoName!) 
        : null;
    PlaceBottomSheet.show(context, place, photoUrl: photoUrl);
  }

  Future<void> _openInMaps(Place place) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pet Services'),
        elevation: 0,
      ),
      body: _isLocating
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ── Map ───────────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      // OpenStreetMap tiles — free, no key required.
                      // Swap for Google Maps tiles if you have a Maps SDK key.
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'pet_connect_app',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // ── Filter chips ──────────────────────────────────────────
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: _FilterBar(
                    active: _activeFilter,
                    onChanged: (f) {
                      setState(() => _activeFilter = f);
                      _search(f);
                    },
                  ),
                ),

                // ── Loading indicator ─────────────────────────────────────
                if (_isSearching)
                  const Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _SearchingBadge(),
                    ),
                  ),

                // ── Error banner ──────────────────────────────────────────
                if (_errorMessage != null && !_isSearching)
                  Positioned(
                    bottom: 90,
                    left: 16,
                    right: 16,
                    child: _ErrorBanner(
                      message: _errorMessage!,
                      onRetry: () => _search(_activeFilter),
                    ),
                  ),

                // ── Results count badge ───────────────────────────────────
                if (!_isSearching && _errorMessage == null && _places.isNotEmpty)
                  Positioned(
                    bottom: 90,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_places.length} found',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),

      // ── FABs ────────────────────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoomIn',
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoomOut',
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'centerLocation',
            onPressed: () =>
                _mapController.move(_currentPosition, _mapController.camera.zoom),
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _Pin extends StatelessWidget {
  const _Pin({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.active, required this.onChanged});
  final _PlaceFilter active;
  final void Function(_PlaceFilter) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in _PlaceFilter.values) ...[
              if (filter != _PlaceFilter.values.first) const SizedBox(width: 6),
              FilterChip(
                label: Text(filter.label,
                    style: const TextStyle(fontSize: 12)),
                selected: active == filter,
                onSelected: (_) => onChanged(filter),
                backgroundColor: Colors.grey[200],
                selectedColor: AppColors.primary.withOpacity(0.15),
                side: active == filter
                    ? BorderSide(color: AppColors.primary, width: 1.5)
                    : BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchingBadge extends StatelessWidget {
  const _SearchingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Searching nearby…',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
