import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

class UserService {
  static final String baseUrl = '${dotenv.env['API_BASE_URL']}/users';

  // Get user profile dengan error handling lebih baik
  static Future<User> getUserProfile(int userId) async {
    try {
      print('🔄 Fetching user profile from: $baseUrl/profile/$userId'); // Debug

      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}'); // Debug
      print('📡 Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('User tidak ditemukan');
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in getUserProfile: $e'); // Debug
      throw Exception('Gagal memuat profil: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(
    int userId,
    User user,
    List<int>? imageBytes,
  ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profile/$userId'),
      );

      request.fields['username'] = user.username;
      request.fields['email'] = user.email;
      request.fields['company_name'] = user.companyName;
      request.fields['alamat'] = user.alamat;

      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            imageBytes,
            filename: 'profile.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception('HTTP Error ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      print('❌ Error in updateUserProfile: $e'); // Debug
      throw Exception('Gagal memperbarui profil: $e');
    }
  }
}
