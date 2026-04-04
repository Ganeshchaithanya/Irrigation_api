class NodeReading {
  final String deviceId;
  final double moisture;
  final double battery;
  final double solar;

  NodeReading({
    required this.deviceId,
    required this.moisture,
    this.battery = 100.0,
    this.solar = 0.0,
  });

  factory NodeReading.fromJson(Map<String, dynamic> json) {
    return NodeReading(
      deviceId: json['device_id'] ?? 'Unknown',
      moisture: (json['soil_moisture'] ?? 0.0).toDouble(),
      battery: (json['battery_percentage'] ?? 100.0).toDouble(),
      solar: (json['solar_voltage'] ?? 0.0).toDouble(),
    );
  }
}

class ZoneModel {
  static const double stressThreshold = 40.0;
  final String id;
  final String name;

  final double moisture; // This will be the average moisture of all nodes
  final double temperature;
  final double humidity;

  final double dryingRate;
  final double timeToStress;
  final double stressScore;

  final String recommendation;
  final double aiConfidence;
  
  final List<NodeReading> nodes;
  
  // Master status fields
  final double currentFlow;
  final bool isRaining;

  ZoneModel({
    required this.id,
    required this.name,
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.dryingRate,
    required this.timeToStress,
    required this.stressScore,
    required this.recommendation,
    required this.aiConfidence,
    this.nodes = const [],
    this.currentFlow = 0.0,
    this.isRaining = false,
  });

  // Helper getters for UI aggregation
  double get batteryLevel {
    if (nodes.isEmpty) return 100.0;
    double total = nodes.fold(0, (sum, node) => sum + node.battery);
    return total / nodes.length;
  }

  double get solarOutput {
    if (nodes.isEmpty) return 0.0;
    double total = nodes.fold(0, (sum, node) => sum + node.solar);
    return total / nodes.length;
  }

  String get status {
    if (stressScore > 80) return 'Critical';
    if (stressScore > 50) return 'Warning';
    return 'Optimal';
  }

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> nodeJsons = json['nodes'] ?? [];
    final List<NodeReading> nodes = nodeJsons.map((nj) => NodeReading.fromJson(nj)).toList();
    
    return ZoneModel(
      id: json['id'] ?? json['zone_id'] ?? '',
      name: json['name'] ?? 'Zone ${json['zone_id']}',
      moisture: (json['moisture'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      dryingRate: (json['drying_rate'] ?? 0.0).toDouble(),
      timeToStress: (json['time_to_stress'] ?? 0.0).toDouble(),
      stressScore: (json['stress_score'] ?? 0.0).toDouble(),
      recommendation: json['recommendation'] ?? 'Healthy',
      aiConfidence: (json['ai_confidence'] ?? 0.0).toDouble(),
      nodes: nodes,
      currentFlow: (json['current_flow'] ?? 0.0).toDouble(),
      isRaining: json['is_raining'] ?? false,
    );
  }
}
