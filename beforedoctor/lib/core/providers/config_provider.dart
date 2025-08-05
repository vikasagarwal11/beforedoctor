import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/app_config.dart';

// Provider for loading environment variables
final envProvider = FutureProvider<void>((ref) async {
  await dotenv.load(fileName: '.env');
});

// Provider for app configuration
final appConfigProvider = Provider<AppConfig>((ref) {
  // Ensure environment is loaded
  ref.watch(envProvider);
  return AppConfig.instance;
});

// Provider for voice API settings
final voiceApiSettingsProvider = Provider<VoiceApiSettings>((ref) {
  final config = ref.watch(appConfigProvider);
  return VoiceApiSettings(
    primaryApi: config.effectivePrimaryApi,
    fallbackApi: config.effectiveFallbackApi,
    autoFallbackEnabled: config.autoFallbackEnabled,
    availableApis: config.availableVoiceApis,
  );
});

// Provider for language settings
final languageSettingsProvider = Provider<LanguageSettings>((ref) {
  final config = ref.watch(appConfigProvider);
  return LanguageSettings(
    defaultLanguage: config.defaultLanguage,
    supportedLanguages: config.supportedLanguages,
  );
});

// Provider for database settings
final databaseSettingsProvider = Provider<DatabaseSettings>((ref) {
  final config = ref.watch(appConfigProvider);
  return DatabaseSettings(
    databaseName: config.sqliteDatabaseName,
    version: config.sqliteVersion,
  );
});

// Data classes for type safety
class VoiceApiSettings {
  final String primaryApi;
  final String fallbackApi;
  final bool autoFallbackEnabled;
  final List<String> availableApis;

  VoiceApiSettings({
    required this.primaryApi,
    required this.fallbackApi,
    required this.autoFallbackEnabled,
    required this.availableApis,
  });

  bool get hasValidConfiguration => availableApis.isNotEmpty;
  bool get canUseFallback => 
      autoFallbackEnabled && fallbackApi != 'none' && fallbackApi != primaryApi;
}

class LanguageSettings {
  final String defaultLanguage;
  final List<String> supportedLanguages;

  LanguageSettings({
    required this.defaultLanguage,
    required this.supportedLanguages,
  });

  bool get isMultilingual => supportedLanguages.length > 1;
  bool supportsLanguage(String language) => 
      supportedLanguages.contains(language);
}

class DatabaseSettings {
  final String databaseName;
  final int version;

  DatabaseSettings({
    required this.databaseName,
    required this.version,
  });
} 