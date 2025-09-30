import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ConfigService {
  static const String _apiUrlKey = 'api_base_url';

  // Simpan URL API ke SharedPreferences
  static Future<void> saveApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String formattedUrl = _formatUrl(url);
    await prefs.setString(_apiUrlKey, formattedUrl);

    // Update dotenv secara runtime
    dotenv.env['API_BASE_URL'] = formattedUrl;
  }

  // Ambil URL API dari SharedPreferences atau dotenv
  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_apiUrlKey);

    if (savedUrl != null) {
      return savedUrl;
    }

    // Fallback ke dotenv
    await dotenv.load(fileName: "assets/.env");
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
  }

  // Format URL untuk konsistensi
  static String _formatUrl(String url) {
    String formatted = url.trim();

    // Tambahkan http:// jika tidak ada
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }

    // Tambahkan /api jika tidak ada
    if (!formatted.endsWith('/api')) {
      formatted = '$formatted/api';
    }

    return formatted;
  }

  // Reset ke default dari .env
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiUrlKey);
    await dotenv.load(fileName: "assets/.env");
  }

  // Test koneksi ke server
  static Future<Map<String, dynamic>> testConnection(String url) async {
    try {
      final testUrl = _formatUrl(url).replaceAll('/api', '') + '/api/test';
      final response = await http
          .get(Uri.parse(testUrl))
          .timeout(const Duration(seconds: 5));

      final success = response.statusCode == 200;
      return {
        'success': success,
        'message': success
            ? 'Koneksi berhasil! Server merespon dengan baik.'
            : 'Server merespon dengan status: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
        'statusCode': 0,
      };
    }
  }

  // Get current URL untuk display (tanpa /api)
  static Future<String> getDisplayUrl() async {
    final url = await getApiUrl();
    return url.replaceAll('/api', '');
  }
}
