import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm_model.dart';

class MockDataService {
  static const String _setupKey = 'aquasol_setup_complete';
  static const String _farmDataKey = 'aquasol_farm_data';

  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupKey) ?? false;
  }

  static Future<void> saveSetup({
    required String farmName,
    required String farmLocation,
    required List<Map<String, dynamic>> acresConfig,
    required String soilType,
    required String cropType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final farmData = _buildFarmData(
      farmName: farmName,
      farmLocation: farmLocation,
      acresConfig: acresConfig,
      soilType: soilType,
      cropType: cropType,
    );
    await prefs.setString(_farmDataKey, jsonEncode(farmData));
    await prefs.setBool(_setupKey, true);
  }

  static Future<FarmModel?> loadFarm() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_farmDataKey);
    if (data == null) return null;
    return FarmModel.fromJson(jsonDecode(data));
  }

  static Future<void> clearSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_setupKey);
    await prefs.remove(_farmDataKey);
  }

  static Map<String, dynamic> _buildFarmData({
    required String farmName,
    required String farmLocation,
    required List<Map<String, dynamic>> acresConfig,
    required String soilType,
    required String cropType,
  }) {
    // Realistic sensor mock values cycled per zone
    final List<double> moisturePool = [62, 55, 71, 48, 67, 58, 74, 52];
    final List<double> tempPool = [27.5, 29.0, 26.8, 30.2, 28.5, 27.0, 31.0, 25.5];
    final List<double> humPool = [65, 58, 72, 61, 68, 54, 75, 63];
    final List<double> stressPool = [8, 22, 15, 45, 12, 30, 18, 38];

    List<Map<String, dynamic>> acres = [];
    int zoneCounter = 0;

    for (int i = 0; i < acresConfig.length; i++) {
      final acreName = acresConfig[i]['name'] as String;
      // Zone nodes configured from the UI
      final List<Map<String, dynamic>> zoneConfigs = acresConfig[i]['zones'] ?? [];
      final int zoneCount = zoneConfigs.length;
      List<Map<String, dynamic>> zones = [];

      for (int j = 0; j < zoneCount; j++) {
        final idx = zoneCounter % moisturePool.length;
        final stress = stressPool[idx];
        
        final config = zoneConfigs[j];
        
        zones.add({
          'zone_id': 'zone-${i + 1}-${j + 1}',
          'name': config['name'] ?? 'Zone ${j + 1}',
          'start_node': config['startNode'] ?? 'Node-A1-S',
          'mid_node': config['midNode'] ?? 'Node-A1-M',
          'end_node': config['endNode'] ?? 'Node-A1-E',
          'moisture': moisturePool[idx],
          'temperature': tempPool[idx],
          'humidity': humPool[idx],
          'drying_rate': 0.7 + (idx * 0.05),
          'time_to_stress': stress > 30 ? 8.0 : 20.0,
          'stress_score': stress,
          'recommendation': stress > 40
              ? 'Irrigation recommended soon — moisture falling below threshold.'
              : 'Soil moisture is optimal. No action needed.',
          'ai_confidence': 0.92 + (idx * 0.008),
        });
        zoneCounter++;
      }

      acres.add({
        'acre_id': 'acre-${i + 1}',
        'name': acreName,
        'crop_type': cropType,
        'soil_type': soilType,
        'growth_stage': 'Vegetative',
        'zones': zones,
      });
    }

    return {
      'farm_id': 'local-farm-001',
      'name': farmName,
      'location': farmLocation,
      'acres': acres,
    };
  }

  // --- Static lists for setup UI ---
  static const List<String> soilTypes = [
    'Clay', 'Sandy', 'Loamy', 'Silty', 'Peaty', 'Chalky', 'Red Laterite',
  ];

  static const List<String> cropTypes = [
    'Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane', 'Soybean', 'Groundnut',
    'Tomato', 'Onion', 'Potato', 'Chilli', 'Banana', 'Mango', 'Turmeric',
  ];
  

}
