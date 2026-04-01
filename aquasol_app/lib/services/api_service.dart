import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use a default for local development, can be overridden via constructor or env.
  final String baseUrl;

  ApiService({this.baseUrl = "http://localhost:8000/api/v1"});

  /// Fetches a consolidated farm snapshot.
  Future<Map<String, dynamic>> getFarmData(String userId) async {
    // 1. Fetch the first farm
    final farmsRes = await http.get(Uri.parse("$baseUrl/farms/my-farms?user_id=$userId"));
    if (farmsRes.statusCode != 200) throw Exception("Failed to load farms");
    
    final List farms = jsonDecode(farmsRes.body);
    if (farms.isEmpty) return {}; // Return empty if no farms
    
    final farm = farms.first;
    final farmId = farm['id'];

    // 2. Fetch acres for the farm
    final acresRes = await http.get(Uri.parse("$baseUrl/farms/acres/$farmId"));
    if (acresRes.statusCode != 200) throw Exception("Failed to load acres");
    final List acres = jsonDecode(acresRes.body);

    // 3. For each acre, fetch zones
    List<Map<String, dynamic>> acreModels = [];
    for (var acre in acres) {
      final acreId = acre['id'];
      final zonesRes = await http.get(Uri.parse("$baseUrl/farms/zones/$acreId"));
      if (zonesRes.statusCode != 200) continue;
      
      final List zones = jsonDecode(zonesRes.body);
      List<Map<String, dynamic>> zoneModels = [];
      
      for (var zone in zones) {
        final zoneId = zone['id'];
        
        final sensorRes = await http.get(Uri.parse("$baseUrl/sensors/latest/zone/$zoneId"));
        final sensorData = (sensorRes.statusCode == 200 && (jsonDecode(sensorRes.body) as List).isNotEmpty) 
            ? (jsonDecode(sensorRes.body) as List).first 
            : {};

        final aiRes = await http.get(Uri.parse("$baseUrl/ai/predictions/$zoneId?limit=1"));
        final aiData = (aiRes.statusCode == 200 && (jsonDecode(aiRes.body) as List).isNotEmpty) 
            ? (jsonDecode(aiRes.body) as List).first 
            : {};

        zoneModels.add({
          "zone_id": zoneId,
          "name": zone['name'],
          "moisture": sensorData['soil_moisture'] ?? 0.0,
          "temperature": sensorData['temperature'] ?? 0.0,
          "humidity": sensorData['humidity'] ?? 0.0,
          "drying_rate": aiData['predicted_moisture'] ?? 0.0,
          "time_to_stress": aiData['hours_until_needed'] ?? 0.0,
          "stress_score": 0.0,
          "recommendation": aiData['recommendation_text'] ?? "Healthy",
          "ai_confidence": 0.95,
        });
      }

      acreModels.add({
        "acre_id": acreId,
        "name": acre['name'],
        "crop_type": zones.isNotEmpty ? zones.first['crop_type'] : "Wheat",
        "soil_type": zones.isNotEmpty ? zones.first['soil_type'] : "Loamy",
        "growth_stage": "Vegetative",
        "zones": zoneModels,
      });
    }

    return {
      "farm_id": farmId,
      "name": farm['name'],
      "location": farm['location'],
      "acres": acreModels,
    };
  }

  // --- Auth Methods ---

  Future<void> requestOtp(String phone) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/request-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );
    if (res.statusCode != 200) throw Exception("Failed to request OTP: ${res.body}");
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "otp_code": code}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Verification failed: ${res.body}");
  }

  // --- Farm Creation Methods ---

  Future<Map<String, dynamic>> createFarm(String name, String location, String userId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/farms/farm?user_id=$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "location": location}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to create farm: ${res.body}");
  }

  Future<Map<String, dynamic>> createAcre(String farmId, String name, double size) async {
    final res = await http.post(
      Uri.parse("$baseUrl/farms/acre"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"farm_id": farmId, "name": name, "size": size}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to create acre: ${res.body}");
  }

  Future<Map<String, dynamic>> createZone({
    required String acreId,
    required String name,
    required String cropType,
    required String soilType,
    String startNode = 'Unknown',
    String midNode = 'Unknown',
    String endNode = 'Unknown',
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
        "start_node": startNode,
        "mid_node": midNode,
        "end_node": endNode,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to create zone: ${res.body}");
  }

  Future<Map<String, dynamic>> getZonePrediction(String zoneId) async {
    final res = await http.get(Uri.parse("$baseUrl/ai/predictions/$zoneId?limit=1"));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.isNotEmpty ? data.first : {};
    }
    throw Exception("Failed to load prediction");
  }

  Future<void> triggerIrrigation(String zoneId, int duration) async {
    final res = await http.post(
      Uri.parse("$baseUrl/irrigation/start"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "zone_id": zoneId,
        "duration": duration,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to trigger irrigation: ${res.body}");
    }
  }

  Future<void> executeAICommand(String zoneId, String action, int duration) async {
    final res = await http.post(
      Uri.parse("$baseUrl/commands/ai-execute"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "zone_id": zoneId,
        "action": action,
        "duration": duration,
      }),
    );
    if (res.statusCode != 200) {
      final errorMsg = jsonDecode(res.body)['detail'] ?? "Execution intercepted by Safety Engine";
      throw Exception(errorMsg);
    }
  }

  Future<String> askAI(String query, {String language = 'English'}) async {
    final String prompt = language == 'English' 
        ? query 
        : "Explain and respond strictly in $language language: $query";

    final res = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": prompt}), 
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['response'] ?? "I'm sorry, I couldn't process that.";
    }
    throw Exception("AI Chat failed");
  }

  // --- Diary Methods ---

  Future<List<Map<String, dynamic>>> getFarmLogs(String farmId) async {
    final res = await http.get(Uri.parse("$baseUrl/farms/diary/$farmId"));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
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
    throw Exception("Failed to create log: ${res.body}");
  }

  // --- User Preferences ---

  Future<void> updateUserPreference(String userId, String language) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/auth/preference/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"preferred_language": language}),
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to update user preference: ${res.body}");
    }
  }

  // --- Crop Planning ---

  Future<Map<String, dynamic>> generateCropPlan(String zoneId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/ai/generate-plan/$zoneId"),
      headers: {"Content-Type": "application/json"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to generate crop plan: ${res.body}");
  }
}
