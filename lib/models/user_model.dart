class User {
  final int id;
  final String username;
  final String email;
  final String companyName;
  final String alamat; // TAMBAHKAN INI
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.companyName,
    required this.alamat, // TAMBAHKAN INI
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      companyName: json['company_name'],
      alamat: json['alamat'] ?? '', // TAMBAHKAN INI
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'company_name': companyName,
      'alamat': alamat, // TAMBAHKAN INI
      'profile_image': profileImage,
    };
  }
}
