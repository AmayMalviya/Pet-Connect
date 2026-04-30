import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_connect_app/models/place.dart';

/// Handles all requests to the Google Places API (New).
///
/// API reference:
///   searchNearby  → POST https://places.googleapis.com/v1/places:searchNearby
///   searchText    → POST https://places.googleapis.com/v1/places:searchText
///
/// Set [apiKey] to your Google Cloud API key (with "Places API (New)" enabled).
class PlaceService {
  PlaceService({required this.apiKey});

  final String apiKey;

  // ── Endpoints ──────────────────────────────────────────────────────────────
  static const _searchNearbyUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const _searchTextUrl =
      'https://places.googleapis.com/v1/places:searchText';

  // Fields we ask Google to return (reduces response size / cost).
  static const _nearbyFieldMask =
      'places.id,places.displayName,places.location,'
      'places.formattedAddress,places.primaryType,'
      'places.primaryTypeDisplayName,places.rating,'
      'places.currentOpeningHours';

  static const _textFieldMask =
      'places.id,places.displayName,places.location,'
      'places.formattedAddress,places.primaryType,'
      'places.primaryTypeDisplayName,places.rating,'
      'places.currentOpeningHours';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetch nearby **vets & pet shops** using `searchNearby` with typed filters.
  ///
  /// [lat] / [lng] – centre point.
  /// [radiusMeters] – search radius (max 50 000).
  /// [maxResults]   – 1–20.
  Future<List<Place>> searchVetsAndPetShops({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int maxResults = 20,
  }) async {
    final body = {
      'includedTypes': ['veterinary_care', 'pet_store'],
      'maxResultCount': maxResults,
      'locationRestriction': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusMeters.toDouble(),
        },
      },
    };

    return _postNearby(body);
  }

  /// Fetch nearby **vets only**.
  Future<List<Place>> searchVets({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int maxResults = 20,
  }) async {
    final body = {
      'includedTypes': ['veterinary_care'],
      'maxResultCount': maxResults,
      'locationRestriction': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusMeters.toDouble(),
        },
      },
    };
    return _postNearby(body);
  }

  /// Fetch nearby **pet shops only**.
  Future<List<Place>> searchPetShops({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int maxResults = 20,
  }) async {
    final body = {
      'includedTypes': ['pet_store'],
      'maxResultCount': maxResults,
      'locationRestriction': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusMeters.toDouble(),
        },
      },
    };
    return _postNearby(body);
  }

  /// Fetch nearby **animal rescue NGOs / shelters** using `searchText`.
  ///
  /// The Places API (New) has no specific type for animal shelters/NGOs,
  /// so we use a text query biased to the given location.
  Future<List<Place>> searchSheltersAndNGOs({
    required double lat,
    required double lng,
    int radiusMeters = 10000,
    int maxResults = 20,
  }) async {
    final body = {
      'textQuery': 'animal rescue NGO shelter',
      'maxResultCount': maxResults,
      'locationBias': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusMeters.toDouble(),
        },
      },
    };

    return _postText(body);
  }

  /// Convenience: returns results for **all** categories combined.
  Future<List<Place>> searchAll({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
  }) async {
    final results = await Future.wait([
      searchVetsAndPetShops(lat: lat, lng: lng, radiusMeters: radiusMeters),
      searchSheltersAndNGOs(lat: lat, lng: lng, radiusMeters: radiusMeters),
    ]);

    // Deduplicate by place id
    final seen = <String>{};
    return [
      for (final list in results)
        for (final place in list)
          if (seen.add(place.id)) place,
    ];
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': _nearbyFieldMask,
      };

  Map<String, String> get _textHeaders => {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': _textFieldMask,
      };

  /// Calls `places:searchNearby` and returns parsed [Place] list.
  Future<List<Place>> _postNearby(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(_searchNearbyUrl),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      return _parseResponse(response, endpoint: 'searchNearby');
    } catch (e) {
      throw PlaceServiceException('Network error in searchNearby: $e');
    }
  }

  /// Calls `places:searchText` and returns parsed [Place] list.
  Future<List<Place>> _postText(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(_searchTextUrl),
            headers: _textHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      return _parseResponse(response, endpoint: 'searchText');
    } catch (e) {
      throw PlaceServiceException('Network error in searchText: $e');
    }
  }

  /// Parses an HTTP response into a list of [Place] objects with full
  /// error handling for billing issues, empty results, and API errors.
  List<Place> _parseResponse(http.Response response,
      {required String endpoint}) {
    // ── Billing / auth errors ────────────────────────────────────────────────
    if (response.statusCode == 403) {
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {}

      final errorCode = _extractErrorCode(body);
      if (errorCode == 'OR_BACR2_44' ||
          (body?['error']?['status'] == 'PERMISSION_DENIED')) {
        throw PlaceServiceException(
          'Billing issue (OR_BACR2_44): Your Google Cloud project does not '
          'have billing enabled, or the "Places API (New)" is not activated. '
          'Visit https://console.cloud.google.com to fix this.',
          code: PlaceErrorCode.billingError,
        );
      }
      throw PlaceServiceException(
        'API key error ($endpoint): ${response.body}',
        code: PlaceErrorCode.authError,
      );
    }

    // ── Generic HTTP errors ──────────────────────────────────────────────────
    if (response.statusCode != 200) {
      throw PlaceServiceException(
        'HTTP ${response.statusCode} from $endpoint: ${response.body}',
        code: PlaceErrorCode.httpError,
      );
    }

    // ── Parse success response ───────────────────────────────────────────────
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw PlaceServiceException('Invalid JSON from $endpoint: $e',
          code: PlaceErrorCode.parseError);
    }

    // searchNearby returns { places: [...] }
    // searchText   returns { places: [...] }
    final places = data['places'];
    if (places == null || (places as List).isEmpty) {
      return const []; // Empty result — not an error
    }

    return places
        .cast<Map<String, dynamic>>()
        .map((p) {
          try {
            return Place.fromJson(p);
          } catch (e) {
            return null; // Skip malformed entries
          }
        })
        .whereType<Place>()
        .toList();
  }

  String? _extractErrorCode(Map<String, dynamic>? body) {
    try {
      final details =
          (body?['error']?['details'] as List?)?.cast<Map<String, dynamic>>();
      if (details == null) return null;
      for (final detail in details) {
        final reason = detail['reason'] as String?;
        if (reason != null) return reason;
      }
    } catch (_) {}
    return null;
  }
}

// ── Error types ───────────────────────────────────────────────────────────────

enum PlaceErrorCode {
  billingError,  // OR_BACR2_44 or billing not enabled
  authError,     // Bad API key / not authorised
  httpError,     // Non-200 HTTP response
  parseError,    // Unexpected JSON shape
  networkError,  // Timeout / no connectivity
}

class PlaceServiceException implements Exception {
  final String message;
  final PlaceErrorCode code;

  const PlaceServiceException(
    this.message, {
    this.code = PlaceErrorCode.networkError,
  });

  @override
  String toString() => 'PlaceServiceException(${code.name}): $message';

  /// Returns a user-friendly string suitable for display in the UI.
  String get userMessage {
    switch (code) {
      case PlaceErrorCode.billingError:
        return 'Google Maps billing is not active. Please contact the app administrator.';
      case PlaceErrorCode.authError:
        return 'API key issue. Please check your Google Cloud configuration.';
      case PlaceErrorCode.httpError:
        return 'Server error. Please try again later.';
      case PlaceErrorCode.parseError:
        return 'Unexpected response from the server.';
      case PlaceErrorCode.networkError:
        return 'No internet connection. Please check your network.';
    }
  }
}
