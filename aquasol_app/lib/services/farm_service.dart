import '../models/farm_model.dart';
import 'api_service.dart';

class FarmService {
  final ApiService api;

  FarmService({ApiService? api}) : api = api ?? ApiService();

  Future<FarmModel> fetchFarm() async {
    // Placeholder for initial development
    final Map<String, dynamic> data = await api.getFarmData("00000000-0000-0000-0000-000000000000");
    return FarmModel.fromJson(data);
  }
}
