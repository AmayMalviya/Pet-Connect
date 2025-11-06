class Profile {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? role;

  Profile({
    required this.userId,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      photoUrl: json['photo_url'],
      role: json['role'],
    );
  }
}
