import 'dart:math';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pet_connect_app/models/service_location.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // HERE Maps API key (add via env vars or config if using HERE Maps)

  final Dio _dio;
  final Map<String, List<ServiceLocation>> _serviceCache = {};

  MapService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  /// Get user's current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied forever');
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        return LatLng(position.latitude, position.longitude);
      }

      return null;
    } catch (e) {
      throw Exception('Error getting location: $e');
    }
  }

  /// Fetch nearby veterinary clinics using Overpass API
  Future<List<ServiceLocation>> getNearbyVeterinaryClinics({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    return _getNearbyServices(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      serviceType: 'veterinary',
      overpassQuery:
          '[out:json];(node["amenity"="veterinary"](around:$radiusMeters,$latitude,$longitude);way["amenity"="veterinary"](around:$radiusMeters,$latitude,$longitude););out center;',
    );
  }

  /// Fetch nearby pet shops using Overpass API
  Future<List<ServiceLocation>> getNearbyPetShops({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    return _getNearbyServices(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      serviceType: 'pet_shop',
      overpassQuery:
          '[out:json];(node["shop"="pet"](around:$radiusMeters,$latitude,$longitude);way["shop"="pet"](around:$radiusMeters,$latitude,$longitude););out center;',
    );
  }

  /// Fetch nearby animal shelters using Overpass API
  Future<List<ServiceLocation>> getNearbyAnimalShelters({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    return _getNearbyServices(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      serviceType: 'animal_shelter',
      overpassQuery:
          '[out:json];(node["amenity"="animal_shelter"](around:$radiusMeters,$latitude,$longitude);way["amenity"="animal_shelter"](around:$radiusMeters,$latitude,$longitude););out center;',
    );
  }

  /// Fetch nearby NGOs using Overpass API
  Future<List<ServiceLocation>> getNearbyNGOs({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    return _getNearbyServices(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      serviceType: 'ngo',
      overpassQuery:
          '[out:json];(node["name"~"animal|rescue|sanctuary|welfare|protection"](around:$radiusMeters,$latitude,$longitude);way["name"~"animal|rescue|sanctuary|welfare|protection"](around:$radiusMeters,$latitude,$longitude););out center;',
    );
  }

  /// Generic method to fetch nearby services
  Future<List<ServiceLocation>> _getNearbyServices({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String serviceType,
    required String overpassQuery,
  }) async {
    try {
      final cacheKey = '${serviceType}_${latitude}_${longitude}';

      // Check cache first
      if (_serviceCache.containsKey(cacheKey)) {
        return _serviceCache[cacheKey]!;
      }

      // Fetch from Overpass API
      final response = await _dio.post(
        _overpassUrl,
        data: overpassQuery,
        options: Options(
          contentType: 'application/osm3s',
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final services = <ServiceLocation>[];
        final elements = response.data['elements'] as List?;

        if (elements != null) {
          for (final element in elements) {
            final service = ServiceLocation.fromOverpassJson(
              element as Map<String, dynamic>,
              serviceType,
            );

            // Calculate distance
            final distance = _calculateDistance(
              latitude,
              longitude,
              service.latitude,
              service.longitude,
            );

            services.add(
              ServiceLocation(
                id: service.id,
                name: service.name,
                serviceType: service.serviceType,
                latitude: service.latitude,
                longitude: service.longitude,
                address: service.address,
                phoneNumber: service.phoneNumber,
                website: service.website,
                rating: service.rating,
                hours: service.hours,
                amenities: service.amenities,
                distance: distance,
              ),
            );
          }
        }

        // Sort by distance
        services.sort(
          (a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999),
        );

        // Cache results
        _serviceCache[cacheKey] = services;

        return services;
      } else {
        throw Exception('Failed to fetch services: $response.statusCode');
      }
    } on DioException catch (e) {
      throw Exception('Network error: $e');
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

  /// Calculate distance between two coordinates using the Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    double degreesToRadians(double degrees) => degrees * (pi / 180);

    final dLat = degreesToRadians(lat2 - lat1);
    final dLon = degreesToRadians(lon2 - lon1);

    final a =
        pow(sin(dLat / 2), 2) +
        cos(degreesToRadians(lat1)) *
            cos(degreesToRadians(lat2)) *
            pow(sin(dLon / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Get all nearby services of multiple types
  Future<List<ServiceLocation>> getNearbyAllServices({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    final veterinary = await getNearbyVeterinaryClinics(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
    final petShops = await getNearbyPetShops(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
    final shelters = await getNearbyAnimalShelters(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
    final ngos = await getNearbyNGOs(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    final all = [...veterinary, ...petShops, ...shelters, ...ngos];
    all.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));

    return all;
  }

  /// Filter services by type
  List<ServiceLocation> filterByServiceType(
    List<ServiceLocation> services,
    List<String> serviceTypes,
  ) {
    if (serviceTypes.isEmpty) return services;

    return services
        .where((service) => serviceTypes.contains(service.serviceType))
        .toList();
  }

  /// Filter services by distance
  List<ServiceLocation> filterByDistance(
    List<ServiceLocation> services,
    double maxDistanceKm,
  ) {
    return services
        .where((service) => (service.distance ?? 999) <= maxDistanceKm)
        .toList();
  }

  /// Get service details from HERE Maps
  Future<Map<String, dynamic>?> getServiceDetailsFromHERE({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // This would require HERE Maps API key
      // Returning null for now as HERE Maps requires authentication
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache management
  void clearCache() {
    _serviceCache.clear();
  }

  void clearCacheForType(String serviceType) {
    _serviceCache.removeWhere((key, _) => key.startsWith(serviceType));
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'totalCacheItems': _serviceCache.length,
      'totalServices': _serviceCache.values.fold(
        0,
        (sum, services) => sum + services.length,
      ),
    };
  }

  /// Calculate route between two points (for HERE Maps integration)
  Future<Map<String, dynamic>?> calculateRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      // This would integrate with HERE Maps Routes API
      // For now, just return basic info
      final distance = _calculateDistance(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      return {'distance': distance, 'unit': 'kilometers'};
    } catch (e) {
      return null;
    }
  }
}
