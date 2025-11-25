class User {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phone;
  final String? city;
  final String? state;
  final String? country;
  final String? idPhotoUrl;
  final String? selfieUrl;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone,
    this.city,
    this.state,
    this.country,
    this.idPhotoUrl,
    this.selfieUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String firstName = json['first_name'] ?? '';
    String lastName = json['last_name'] ?? '';
    String displayName = '$firstName $lastName'.trim();
    if (displayName.isEmpty) {
      displayName = json['displayName'] ?? 'No Display Name';
    }


    return User(
      uid: json['user_id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: displayName,
      photoUrl: json['photoUrl'],
      phone: json['phone'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      idPhotoUrl: json['id_photo_url'],
      selfieUrl: json['selfie_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'city': city,
      'state': state,
      'country': country,
      'id_photo_url': idPhotoUrl,
      'selfie_url': selfieUrl,
    };
  }
}