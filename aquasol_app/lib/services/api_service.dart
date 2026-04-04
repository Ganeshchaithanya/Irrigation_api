import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

String _getBaseUrl() {
  if (kIsWeb) return "http://localhost:8000/api/v1";
  try {
    if (Platform.isAndroid) return "http://10.0.2.2:8000/api/v1";
  } catch (_) {}
  return "http://localhost:8000/api/v1";
}

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _getBaseUrl();
  Future<Map<String, dynamic>> getFarmData(String userId) async {
    try {
      final farmsRes = await http.get(Uri.parse("$baseUrl/farms/my-farms?user_id=$userId"));
      if (farmsRes.statusCode != 200) throw Exception("Network Error: ${farmsRes.body}");
      
      final List farms = jsonDecode(farmsRes.body);
      if (farms.isEmpty) return {}; 
      
      final farm = farms.first;
      final farmId = farm['id'];

      final masterRes = await http.get(Uri.parse("$baseUrl/sensors/master/latest"));
      final masterData = (masterRes.statusCode == 200) ? jsonDecode(masterRes.body) : {};

      final acresRes = await http.get(Uri.parse("$baseUrl/farms/acres/$farmId"));
      if (acresRes.statusCode != 200) throw Exception("Topology Load Failure: ${acresRes.body}");
      final List acres = jsonDecode(acresRes.body);

      List<Map<String, dynamic>> acreModels = [];
      for (var acre in acres) {
        final acreId = acre['id'];
        final zonesRes = await http.get(Uri.parse("$baseUrl/farms/zones/$acreId"));
        if (zonesRes.statusCode != 200) continue;
        
        final List zones = jsonDecode(zonesRes.body);
        List<Map<String, dynamic>> zoneModels = [];
        
        for (var zone in zones) {
          final zoneId = zone['id'];
          final nodesRes = await http.get(Uri.parse("$baseUrl/sensors/latest/zone/$zoneId"));
          final List nodesArray = (nodesRes.statusCode == 200) ? jsonDecode(nodesRes.body) : [];
          final envRes = await http.get(Uri.parse("$baseUrl/sensors/zone/$zoneId/environment"));
          final envData = (envRes.statusCode == 200) ? jsonDecode(envRes.body) : {};
          final aiRes = await http.get(Uri.parse("$baseUrl/ai/predictions/$zoneId?limit=1"));
          final aiData = (aiRes.statusCode == 200 && (jsonDecode(aiRes.body) as List).isNotEmpty) 
              ? (jsonDecode(aiRes.body) as List).first 
              : {};

          double avgMoisture = 0.0;
          if (nodesArray.isNotEmpty) {
            double total = 0.0;
            for (var n in nodesArray) {
              total += (n['soil_moisture'] ?? 0.0);
            }
            avgMoisture = total / nodesArray.length;
          }

          zoneModels.add({
            "zone_id": zoneId,
            "name": zone['name'],
            "moisture": avgMoisture,
            "temperature": envData?['temperature'] ?? 0.0,
            "humidity": envData?['humidity'] ?? 0.0,
            "drying_rate": aiData['predicted_moisture'] ?? 0.0,
            "time_to_stress": aiData['hours_until_needed'] ?? 0.0,
            "stress_score": 0.0,
            "recommendation": aiData['recommendation_text'] ?? "Precision Sync Active",
            "ai_confidence": 0.95,
            "nodes": nodesArray,
            "current_flow": masterData?['flow_rate'] ?? 0.0,
            "is_raining": masterData?['is_raining'] ?? false,
          });
        }

        acreModels.add({
          "acre_id": acreId,
          "name": acre['name'],
          "crop_type": zones.isNotEmpty ? zones.first['crop_type'] : "Default",
          "soil_type": zones.isNotEmpty ? zones.first['soil_type'] : "Standard",
          "growth_stage": "Monitoring",
          "zones": zoneModels,
        });
      }

      return {
        "farm_id": farmId,
        "name": farm['name'],
        "location": farm['location'],
        "acres": acreModels,
      };
    } catch (e) {
      throw Exception("Dynamic Sync Failed: $e");
    }
  }

  // ── Secure Authentication Engine ──────────────────────────────

  Future<void> requestOtp(String phone) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/request-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );
    if (res.statusCode != 200) throw Exception("Identity Verification Locked: ${res.body}");
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "otp_code": code}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Authentication Rejected: ${res.body}");
  }

  Future<void> register(String name, String phone, String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name, 
        "phone": phone,
        "email": email,
        "password": password
      }),
    );
    if (res.statusCode != 200) throw Exception("Registration Failed: ${res.body}");
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Login Rejected: ${res.body}");
  }

  Future<Map<String, dynamic>> googleLogin(String email, String name, String googleId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "name": name, "google_id": googleId}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Google Sign-In Failed: ${res.body}");
  }

  Future<void> updateUserPreference(String userId, String language) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/auth/preference/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"preferred_language": language}),
    );
    if (res.statusCode != 200) throw Exception("Preference Sync Failed");
  }

  // ── Precision Controls & AI Actions ───────────────────────────

  Future<void> triggerIrrigation(String zoneId, int duration) async {
    final res = await http.post(
      Uri.parse("$baseUrl/irrigation/start"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"zone_id": zoneId, "duration": duration}),
    );
    if (res.statusCode != 200) throw Exception("Command Rejected: ${res.body}");
  }

  Future<void> executeAICommand(String zoneId, String action, int duration) async {
    final res = await http.post(
      Uri.parse("$baseUrl/commands/ai-execute"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"zone_id": zoneId, "action": action, "duration": duration}),
    );
    if (res.statusCode != 200) throw Exception("AI Command Intercepted");
  }

  Future<String> askAI(String query, {required String userId, String language = 'English'}) async {
    final String prompt = language == 'English' 
        ? query 
        : "Explain and respond strictly in $language language: $query";

    final res = await http.post(
      Uri.parse("$baseUrl/chat/message"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "query": prompt, "language": language}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['response'];
    throw Exception("AI Insight Unavailable");
  }

  // ── Resource Creation ─────────────────────────────────────────

  Future<Map<String, dynamic>> createFarm(String name, String location, String userId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/farms/farm?user_id=$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "location": location}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Topology Save Error");
  }

  Future<Map<String, dynamic>> createAcre(String farmId, String name, double size) async {
    final res = await http.post(
      Uri.parse("$baseUrl/farms/acre"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"farm_id": farmId, "name": name, "size": size}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Acre Save Error");
  }

  Future<Map<String, dynamic>> createZone({
    required String acreId,
    required String name,
    required String cropType,
    required String soilType,
    List<String> nodes = const [],
    String mode = 'AUTO',
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/farms/zone"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "acre_id": acreId,
        "name": name,
        "crop_type": cropType,
        "soil_type": soilType,
        "mode": mode,
        "nodes": nodes,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Zone Deployment Failure");
  }

  // ── Diary & Planning ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFarmLogs(String farmId) async {
    final res = await http.get(Uri.parse("$baseUrl/farms/diary/$farmId"));
    if (res.statusCode == 200) return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> createFarmLog({
    required String farmId,
    required String title,
    required String description,
    String eventType = "action",
    String iconName = "edit2",
    String colorHex = "#10b981",
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/farms/diary/$farmId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title,
        "description": description,
        "event_type": eventType,
        "icon_name": iconName,
        "color_hex": colorHex,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Diary Log Failed");
  }

  Future<Map<String, dynamic>> generateCropPlan(String zoneId) async {
    final res = await http.post(Uri.parse("$baseUrl/ai/generate-plan/$zoneId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Crop Planning Error");
  }
}
