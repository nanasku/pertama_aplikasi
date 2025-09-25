class User {
  final int id;
  final String username;
  final String email;
  final String companyName;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.companyName,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      companyName: json['company_name'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'company_name': companyName,
      'profile_image': profileImage,
    };
  }
}
