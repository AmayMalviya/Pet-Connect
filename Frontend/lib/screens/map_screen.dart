import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pet_connect_app/theme/app_theme.dart' show AppColors;

class MapScreen extends StatefulWidget {
  static const routeName = '/map';
  final String? placeType;

  const MapScreen({super.key, this.placeType});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static String _dotenvValue(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      // `flutter_dotenv` throws NotInitializedError when not loaded.
      return '';
    }
  }

  static String get _hereApiKey =>
      const String.fromEnvironment('HERE_API_KEY').isNotEmpty
      ? const String.fromEnvironment('HERE_API_KEY')
      : _dotenvValue('HERE_API_KEY');
  static String get _hereAccessKeyId =>
      const String.fromEnvironment('HERE_ACCESS_KEY_ID').isNotEmpty
      ? const String.fromEnvironment('HERE_ACCESS_KEY_ID')
      : _dotenvValue('HERE_ACCESS_KEY_ID');
  static String get _hereAccessKeySecret =>
      const String.fromEnvironment('HERE_ACCESS_KEY_SECRET').isNotEmpty
      ? const String.fromEnvironment('HERE_ACCESS_KEY_SECRET')
      : _dotenvValue('HERE_ACCESS_KEY_SECRET');

  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _selectedPlaceType = 'vets';
  String? _hereBearerToken;
  DateTime? _hereBearerTokenExpiry;
  bool _hereAuthInitAttempted = false;

  @override
  void initState() {
    super.initState();
    _selectedPlaceType = widget.placeType ?? 'vets';
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    _currentPosition = const LatLng(22.719568, 75.857727); // Indore, MP, India
    setState(() {
      _isLoading = false;
      _markers
        ..clear()
        ..add(
          _buildMarker(
            position: _currentPosition!,
            label: 'Your Location',
            isCurrentLocation: true,
          ),
        );
    });
    await _ensureHereAuth();
    _searchNearbyPlaces();
  }

  Future<void> _ensureHereAuth() async {
    if (_hereApiKey.isNotEmpty) return;
    if (_hereBearerToken != null &&
        _hereBearerTokenExpiry != null &&
        DateTime.now().isBefore(
          _hereBearerTokenExpiry!.subtract(const Duration(minutes: 2)),
        )) {
      return;
    }
    if (_hereAccessKeyId.isEmpty || _hereAccessKeySecret.isEmpty) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://account.api.here.com/oauth2/token'),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': _hereAccessKeyId,
          'client_secret': _hereAccessKeySecret,
        },
      );
      if (response.statusCode != 200) return;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final expiresIn = data['expires_in'];
      if (accessToken == null || expiresIn == null) return;

      final expiresSeconds = (expiresIn as num).toInt();
      _hereBearerToken = accessToken;
      _hereBearerTokenExpiry = DateTime.now().add(
        Duration(seconds: expiresSeconds),
      );
    } finally {
      _hereAuthInitAttempted = true;
      if (mounted) setState(() {});
    }
  }

  Map<String, String>? get _hereAuthHeaders {
    if (_hereBearerToken == null) return null;
    return {'Authorization': 'Bearer $_hereBearerToken'};
  }

  Marker _buildMarker({
    required LatLng position,
    required String label,
    bool isCurrentLocation = false,
  }) {
    return Marker(
      point: position,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () async {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(label),
              content: const Text(
                'Do you want to open this location in HERE WeGo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _launchHereMaps(
                      position.latitude,
                      position.longitude,
                      label,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isCurrentLocation ? Colors.red : Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.place, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Future<void> _searchNearbyPlaces({String? type, String? keyword}) async {
    if (_currentPosition == null) return;
    await _ensureHereAuth();

    setState(() {
      _markers.removeWhere((m) => m.point != _currentPosition);
    });

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final query = keyword ?? _queryForType(type ?? _selectedPlaceType);
    final url = _hereApiKey.isNotEmpty
        ? 'https://discover.search.hereapi.com/v1/discover?at=$lat,$lng&q=${Uri.encodeComponent(query)}&limit=20&apiKey=$_hereApiKey'
        : 'https://discover.search.hereapi.com/v1/discover?at=$lat,$lng&q=${Uri.encodeComponent(query)}&limit=20';

    final response = await http.get(
      Uri.parse(url),
      headers: _hereApiKey.isNotEmpty ? null : _hereAuthHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = (data['items'] as List?) ?? const [];
      for (final item in items) {
        final position = item['position'];
        if (position == null) continue;
        final itemLat = position['lat'];
        final itemLng = position['lng'];
        if (itemLat == null || itemLng == null) continue;

        final title = (item['title'] as String?) ?? 'Place';
        setState(() {
          _markers.add(
            _buildMarker(
              position: LatLng(
                (itemLat as num).toDouble(),
                (itemLng as num).toDouble(),
              ),
              label: title,
            ),
          );
        });
      }
    }
  }

  String _queryForType(String type) {
    switch (type) {
      case 'veterinary_care':
      case 'vets':
        return 'veterinary clinic animal hospital';
      case 'pet_store':
      case 'petShops':
        return 'pet store pet shop';
      case 'shelter':
        return 'animal shelter dog shelter cat rescue humane society';
      case 'ngo':
        return 'animal ngo animal welfare animal rescue animal protection';
      default:
        return type;
    }
  }

  Future<void> _launchHereMaps(double lat, double lng, String label) async {
    final url =
        'https://share.here.com/l/$lat,$lng,${Uri.encodeComponent(label)}?z=16&t=normal';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _onFilterChanged(String filter) async {
    setState(() {
      _selectedPlaceType = filter;
      _markers.removeWhere((m) => m.point != _currentPosition);
    });

    if (filter == 'all') {
      // Search for all service types
      await _searchNearbyPlaces(type: 'vets');
      await Future.delayed(const Duration(milliseconds: 200));
      await _searchNearbyPlaces(type: 'pet_store');
      await Future.delayed(const Duration(milliseconds: 200));
      await _searchNearbyPlaces(type: 'shelter');
      await Future.delayed(const Duration(milliseconds: 200));
      await _searchNearbyPlaces(type: 'ngo');
    } else if (filter == 'shelter') {
      // Multiple keywords for shelters
      final keywords = [
        'animal shelter',
        'pet adoption center',
        'dog shelter',
        'cat rescue',
        'humane society',
        'SPCA',
        'animal welfare',
      ];
      for (String keyword in keywords) {
        await _searchNearbyPlaces(keyword: keyword);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else if (filter == 'ngo') {
      // Multiple keywords for NGOs
      final keywords = [
        'animal ngo',
        'animal welfare',
        'animal rescue',
        'animal protection',
        'wildlife sanctuary',
        'pet foundation',
      ];
      for (String keyword in keywords) {
        await _searchNearbyPlaces(keyword: keyword);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      _searchNearbyPlaces(type: filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSomeAuthInput =
        _hereApiKey.isNotEmpty ||
        (_hereAccessKeyId.isNotEmpty && _hereAccessKeySecret.isNotEmpty);
    final authReady = _hereApiKey.isNotEmpty || _hereBearerToken != null;
    final missingHereAuth = !hasSomeAuthInput;
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Pet Services')),
      body: _isLoading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : missingHereAuth
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Missing HERE auth.\n\nRun with either:\n--dart-define=HERE_API_KEY=<YOUR_KEY>\n\nor:\n--dart-define=HERE_ACCESS_KEY_ID=<YOUR_ID> --dart-define=HERE_ACCESS_KEY_SECRET=<YOUR_SECRET>',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : !authReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _hereApiKey.isNotEmpty
                          ? 'https://maps.hereapi.com/v3/base/mc/{z}/{x}/{y}/png?style=explore.day&apiKey=$_hereApiKey'
                          : 'https://maps.hereapi.com/v3/base/mc/{z}/{x}/{y}/png?style=explore.day',
                      userAgentPackageName: 'pet_connect_app',
                      tileProvider: NetworkTileProvider(
                        headers: _hereApiKey.isNotEmpty
                            ? null
                            : _hereAuthHeaders,
                      ),
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        height: 50.0,
                        child: IntrinsicWidth(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              FilterChip(
                                label: const Text('🏥 Veterinary'),
                                selected: _selectedPlaceType == 'vets',
                                onSelected: (_) => _onFilterChanged('vets'),
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                side: _selectedPlaceType == 'vets'
                                    ? BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : BorderSide(color: Colors.grey[300]!),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('🛍️ Pet Shops'),
                                selected: _selectedPlaceType == 'pet_store',
                                onSelected: (_) =>
                                    _onFilterChanged('pet_store'),
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                side: _selectedPlaceType == 'pet_store'
                                    ? BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : BorderSide(color: Colors.grey[300]!),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('🏠 Shelters'),
                                selected: _selectedPlaceType == 'shelter',
                                onSelected: (_) => _onFilterChanged('shelter'),
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                side: _selectedPlaceType == 'pet_store'
                                    ? BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : BorderSide(color: Colors.grey[300]!),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('❤️ NGOs'),
                                selected: _selectedPlaceType == 'ngo',
                                onSelected: (_) => _onFilterChanged('ngo'),
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                side: _selectedPlaceType == 'ngo'
                                    ? BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : BorderSide(color: Colors.grey[300]!),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('🐾 All Services'),
                                selected: _selectedPlaceType == 'all',
                                onSelected: (_) => _onFilterChanged('all'),
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                side: _selectedPlaceType == 'all'
                                    ? BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : BorderSide(color: Colors.grey[300]!),
                              ),
                            ],
                          ),
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
            onPressed: () => _mapController.move(
              _currentPosition!,
              _mapController.camera.zoom,
            ),
            heroTag: "centerLocation",
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
            heroTag: "zoomIn",
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
