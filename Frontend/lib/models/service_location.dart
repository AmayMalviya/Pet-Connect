class ServiceLocation {
  final String id;
  final String name;
  final String serviceType; // 'veterinary', 'pet_shop', 'animal_shelter', 'ngo'
  final double latitude;
  final double longitude;
  final String? address;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final String? hours;
  final List<String>? amenities;
  final double? distance; // in kilometers from user location

  ServiceLocation({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phoneNumber,
    this.website,
    this.rating,
    this.hours,
    this.amenities,
    this.distance,
  });

  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    return ServiceLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      serviceType:
          json['serviceType'] as String? ??
          json['service_type'] as String? ??
          'unknown',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      address: json['address'] as String?,
      phoneNumber:
          json['phoneNumber'] as String? ?? json['phone_number'] as String?,
      website: json['website'] as String?,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      hours: json['hours'] as String?,
      amenities: json['amenities'] is List
          ? List<String>.from(json['amenities'])
          : null,
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
    );
  }

  factory ServiceLocation.fromOverpassJson(
    Map<String, dynamic> json,
    String serviceType,
  ) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};

    return ServiceLocation(
      id: json['id'].toString(),
      name: tags['name'] as String? ?? 'Unknown Service',
      serviceType: serviceType,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      address: tags['address'] as String?,
      phoneNumber: tags['phone'] as String?,
      website: tags['website'] as String? ?? tags['url'] as String?,
      hours: tags['opening_hours'] as String?,
      amenities: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service_type': serviceType,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone_number': phoneNumber,
      'website': website,
      'rating': rating,
      'hours': hours,
      'amenities': amenities,
      'distance': distance,
    };
  }

  String getServiceTypeLabel() {
    switch (serviceType.toLowerCase()) {
      case 'veterinary':
        return 'Veterinary Clinic';
      case 'pet_shop':
        return 'Pet Shop';
      case 'animal_shelter':
        return 'Animal Shelter';
      case 'ngo':
        return 'Animal NGO';
      default:
        return serviceType;
    }
  }

  static String getServiceTypeIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'veterinary':
        return '🏥';
      case 'pet_shop':
        return '🛍️';
      case 'animal_shelter':
        return '🏠';
      case 'ngo':
        return '❤️';
      default:
        return '📍';
    }
  }
}
