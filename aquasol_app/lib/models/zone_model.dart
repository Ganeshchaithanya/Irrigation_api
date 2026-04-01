class ZoneModel {
  static const double stressThreshold = 40.0;
  final String id;
  final String name;

  final double moisture;
  final double temperature;
  final double humidity;

  final double dryingRate;
  final double timeToStress;
  final double stressScore;

  final String recommendation;
  final double aiConfidence;
  
  // Hardware integration fields
  final String startNode;
  final String midNode;
  final String endNode;

  final double solarOutput;
  final double batteryLevel;

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
    this.startNode = 'Unknown',
    this.midNode = 'Unknown',
    this.endNode = 'Unknown',
    this.solarOutput = 0.0,
    this.batteryLevel = 100.0,
  });

  String get status {
    if (stressScore > 80) return 'Critical';
    if (stressScore > 50) return 'Warning';
    return 'Optimal';
  }

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
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
      startNode: json['start_node'] ?? 'Unknown',
      midNode: json['mid_node'] ?? 'Unknown',
      endNode: json['end_node'] ?? 'Unknown',
      solarOutput: (json['solar_voltage'] ?? 0.0).toDouble(),
      batteryLevel: (json['battery_percentage'] ?? 0.0).toDouble(),
    );
  }
}
