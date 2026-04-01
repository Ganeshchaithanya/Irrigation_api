import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquasol_app/services/api_service.dart';
import 'package:aquasol_app/providers/farm_provider.dart';

// Supported languages
const List<String> supportedLanguages = [
  'English',
  'Hindi',
  'Telugu',
  'Kannada',
];

class LanguageNotifier extends StateNotifier<String> {
  final Ref _ref;

  LanguageNotifier(this._ref) : super('English');

  Future<void> setLanguage(String language) async {
    if (supportedLanguages.contains(language)) {
      state = language;
      
      try {
        // Sync with backend if user is loaded
        final farmAsync = _ref.read(farmProvider);
        if (farmAsync.hasValue && farmAsync.value != null) {
          final userId = farmAsync.value!.id; 
          await ApiService().updateUserPreference(userId, language);
        }
      } catch (e) {
        // Silently fail or use a logger for sync errors
      }
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref);
});
