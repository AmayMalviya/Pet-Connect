/// Model for a place returned by Google Places API (New).
class Place {
  final String id;
  final String displayName;
  final String? formattedAddress;
  final double latitude;
  final double longitude;
  final String? primaryType;
  final double? rating;
  final int? userRatingCount;
  final bool isOpen;
  final String? nationalPhoneNumber;
  final String? websiteUri;
  final List<String> weekdayDescriptions;
  final String? photoName;

  const Place({
    required this.id,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.primaryType,
    this.rating,
    this.userRatingCount,
    this.isOpen = false,
    this.nationalPhoneNumber,
    this.websiteUri,
    this.weekdayDescriptions = const [],
    this.photoName,
  });

  /// Parse from a Places API (New) place object.
  factory Place.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final nameMap = json['displayName'] as Map<String, dynamic>? ?? {};
    final openingHours = json['currentOpeningHours'] as Map<String, dynamic>?;
    final regularOpeningHours = json['regularOpeningHours'] as Map<String, dynamic>?;
    final weekdayDescriptions = (regularOpeningHours?['weekdayDescriptions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
    
    String? photoName;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoName = json['photos'][0]['name'] as String?;
    }

    return Place(
      id: json['id'] as String? ?? '',
      displayName: nameMap['text'] as String? ?? 'Unknown Place',
      formattedAddress: json['formattedAddress'] as String?,
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
      primaryType: json['primaryTypeDisplayName'] != null
          ? (json['primaryTypeDisplayName']['text'] as String?)
          : (json['primaryType'] as String?),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['userRatingCount'] as int?,
      isOpen: openingHours?['openNow'] as bool? ?? false,
      nationalPhoneNumber: json['nationalPhoneNumber'] as String?,
      websiteUri: json['websiteUri'] as String?,
      weekdayDescriptions: weekdayDescriptions,
      photoName: photoName,
    );
  }

  @override
  String toString() => 'Place($displayName @ $latitude,$longitude)';
}
