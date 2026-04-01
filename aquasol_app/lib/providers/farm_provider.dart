import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_model.dart';
import '../models/zone_model.dart';
import '../providers/auth_provider.dart';

final farmProvider =
    StateNotifierProvider<FarmNotifier, AsyncValue<FarmModel>>(
  (ref) => FarmNotifier(ref),
);

/// Derived providers for specific UI needs
final allZonesProvider = Provider<List<ZoneModel>>((ref) {
  final farmAsync = ref.watch(farmProvider);
  return farmAsync.maybeWhen(
    data: (farm) => farm.acres.expand((a) => a.zones).toList(),
    orElse: () => [],
  );
});

final stressedZoneProvider = Provider<ZoneModel?>((ref) {
  final zones = ref.watch(allZonesProvider);
  if (zones.isEmpty) return null;
  return zones.reduce((a, b) => a.stressScore > b.stressScore ? a : b);
});

class FarmNotifier extends StateNotifier<AsyncValue<FarmModel>> {
  final Ref _ref;
  FarmNotifier(this._ref) : super(const AsyncLoading()) {
    _init();
  }

  void _init() {
    loadFarm();
  }

  Future<void> loadFarm({bool silent = false}) async {
    if (!silent) state = const AsyncLoading();

    try {
      final auth = _ref.read(authProvider);
      final userId = auth.userId ?? 'demo-user-001'; 

      final api = _ref.read(apiServiceProvider);
      final data = await api.getFarmData(userId);
      
      if (data.isEmpty) {
        state = const AsyncValue.error(
          'No farm found. Please complete setup.',
          StackTrace.empty,
        );
        return;
      }

      final farm = FarmModel.fromJson(data);
      state = AsyncValue.data(farm);
    } catch (e, st) {
      if (!silent) {
        state = AsyncValue.error(e, st);
      } else {
        debugPrint('Silent update failed: $e');
      }
    }
  }

  Future<void> refresh() async => loadFarm();
  Future<void> reloadAfterSetup() async => loadFarm();
}
