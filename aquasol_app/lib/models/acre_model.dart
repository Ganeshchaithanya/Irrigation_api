import 'zone_model.dart';

class AcreModel {
  final String id;
  final String cropType;
  final String soilType;
  final String growthStage;
  final List<ZoneModel> zones;

  AcreModel({
    required this.id,
    required this.cropType,
    required this.soilType,
    required this.growthStage,
    required this.zones,
  });

  factory AcreModel.fromJson(Map<String, dynamic> json) {
    return AcreModel(
      id: json['acre_id'] ?? '',
      cropType: json['crop_type'] ?? 'Unknown',
      soilType: json['soil_type'] ?? 'Unknown',
      growthStage: json['growth_stage'] ?? 'Unknown',
      zones: (json['zones'] as List?)
              ?.map((e) => ZoneModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
