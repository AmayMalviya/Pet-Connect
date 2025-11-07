class User {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phone;
  final String? city;
  final String? state;
  final String? country;
  final String? idPhotoPath;
  final String? selfiePath;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone,
    this.city,
    this.state,
    this.country,
    this.idPhotoPath,
    this.selfiePath,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? 'No Display Name',
      photoUrl: json['photoUrl'],
      phone: json['phone'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      idPhotoPath: json['id_photo_path'],
      selfiePath: json['selfie_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'city': city,
      'state': state,
      'country': country,
      'id_photo_path': idPhotoPath,
      'selfie_path': selfiePath,
    };
  }
}