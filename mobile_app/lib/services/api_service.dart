import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Central API client.
///
/// Use the same backend host/port that is running locally.
/// - Android emulator -> http://10.0.2.2:8001
/// - iOS simulator    -> http://127.0.0.1:8001
/// - Physical device   -> http://<your-computer-LAN-IP>:8001
///
/// You can override this at build time with:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.4:8001
class ApiService {
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.4:8001',
  );

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _token();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------- AUTH ----------------
  static Future<AppUser> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Login failed');
    }
    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token']);
    return AppUser.fromJson(data['user']);
  }

  static Future<AppUser> register(String name, String email, String password, String role) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'full_name': name, 'email': email, 'password': password, 'role': role}),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Registration failed');
    }
    // auto-login after registration
    return login(email, password);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<bool> isLoggedIn() async => (await _token()) != null;

  // ---------------- PROPERTIES ----------------
  static Future<PropertyModel> searchBySurveyNumber(String surveyNumber) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/properties/search?survey_number=${Uri.encodeComponent(surveyNumber)}'),
      headers: await _headers(),
    );
    if (res.statusCode == 404) throw Exception('No property found for survey number "$surveyNumber"');
    if (res.statusCode != 200) throw Exception('Search failed');
    return PropertyModel.fromJson(jsonDecode(res.body));
  }

  static Future<List<PropertyModel>> listProperties() async {
    final res = await http.get(Uri.parse('$baseUrl/api/properties'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load properties');
    return (jsonDecode(res.body) as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  static Future<List<PropertyModel>> compareProperties(List<String> surveyNumbers) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/properties/compare'),
      headers: await _headers(),
      body: jsonEncode({'survey_numbers': surveyNumbers}),
    );
    if (res.statusCode != 200) throw Exception('Comparison failed');
    return (jsonDecode(res.body) as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  // ---------------- AI ----------------
  static Future<RiskAssessment> getRiskScore(String surveyNumber) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/ai/risk-score?survey_number=${Uri.encodeComponent(surveyNumber)}'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Risk assessment failed');
    return RiskAssessment.fromJson(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> getFraudFlags(String surveyNumber) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/ai/fraud-flags?survey_number=${Uri.encodeComponent(surveyNumber)}'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Fraud check failed');
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> extractDocument(String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/ai/extract-document'),
      headers: await _headers(),
      body: jsonEncode({'document_text': text}),
    );
    if (res.statusCode != 200) throw Exception('Document extraction failed');
    return jsonDecode(res.body);
  }

  // ---------------- REPORTS ----------------
  static Future<String> generateReport(String surveyNumber) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/reports/generate?survey_number=${Uri.encodeComponent(surveyNumber)}'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Report generation failed');
    final data = jsonDecode(res.body);
    return '$baseUrl${data['download_url']}';
  }

  // ---------------- ALERTS ----------------
  static Future<List<AlertModel>> getAlerts() async {
    final res = await http.get(Uri.parse('$baseUrl/api/alerts'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load alerts');
    return (jsonDecode(res.body) as List).map((e) => AlertModel.fromJson(e)).toList();
  }

  static String get wsUrl => baseUrl.replaceFirst('http', 'ws') + '/ws/alerts';
}
