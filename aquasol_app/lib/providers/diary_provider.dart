import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquasol_app/services/api_service.dart';
import 'package:aquasol_app/providers/farm_provider.dart';

final diaryLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final farmAsync = ref.watch(farmProvider);
  
  if (farmAsync.hasValue && farmAsync.value != null) {
    final farmId = farmAsync.value!.id;
    if (farmId.isNotEmpty) {
      return await ApiService().getFarmLogs(farmId);
    }
  }
  
  return [];
});
