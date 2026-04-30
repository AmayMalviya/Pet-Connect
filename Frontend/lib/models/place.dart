/// Model for a place returned by Google Places API (New).
class Place {
  final String id;
  final String displayName;
  final String? formattedAddress;
  final double latitude;
  final double longitude;
  final String? primaryType;
  final double? rating;
  final bool isOpen;

  const Place({
    required this.id,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.primaryType,
    this.rating,
    this.isOpen = false,
  });

  /// Parse from a Places API (New) place object.
  factory Place.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final nameMap = json['displayName'] as Map<String, dynamic>? ?? {};
    final openingHours = json['currentOpeningHours'] as Map<String, dynamic>?;

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
      isOpen: openingHours?['openNow'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'Place($displayName @ $latitude,$longitude)';
}
