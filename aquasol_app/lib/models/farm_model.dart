import 'acre_model.dart';

class FarmModel {
  final String id;
  final String name;
  final String location;
  final List<AcreModel> acres;

  FarmModel({
    required this.id,
    required this.name,
    required this.location,
    required this.acres,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['farm_id'] ?? '',
      name: json['name'] ?? 'Unnamed Farm',
      location: json['location'] ?? 'Unknown Location',
      acres: (json['acres'] as List?)
              ?.map((e) => AcreModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
