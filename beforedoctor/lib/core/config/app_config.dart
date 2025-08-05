import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._internal();

  AppConfig._internal();

  // Voice APIs
  String get xaiGrokApiKey => dotenv.env['XAI_GROK_API_KEY'] ?? '';
  String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // Weather API
  String get openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  // Firebase Configuration
  String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  // App Configuration
  String get appName => dotenv.env['APP_NAME'] ?? 'BeforeDoctor';
  String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  // Voice API Settings
  String get primaryVoiceApi => dotenv.env['PRIMARY_VOICE_API'] ?? 'grok';
  String get fallbackVoiceApi => dotenv.env['FALLBACK_VOICE_API'] ?? 'openai';
  bool get autoFallbackEnabled => 
      dotenv.env['AUTO_FALLBACK_ENABLED']?.toLowerCase() == 'true';

  // Language Settings
  String get defaultLanguage => dotenv.env['DEFAULT_LANGUAGE'] ?? 'en';
  List<String> get supportedLanguages => 
      dotenv.env['SUPPORTED_LANGUAGES']?.split(',') ?? ['en'];

  // Database Configuration
  String get sqliteDatabaseName => 
      dotenv.env['SQLITE_DATABASE_NAME'] ?? 'beforedoctor.db';
  int get sqliteVersion => int.tryParse(dotenv.env['SQLITE_VERSION'] ?? '1') ?? 1;

  // Testing Configuration
  bool get testMode => dotenv.env['TEST_MODE']?.toLowerCase() == 'true';
  int get syntheticLogsCount => 
      int.tryParse(dotenv.env['SYNTHETIC_LOGS_COUNT'] ?? '100') ?? 100;

  // AI Singing Response
  String get elevenLabsApiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  String get elevenLabsVoiceId => dotenv.env['ELEVENLABS_VOICE_ID'] ?? '';
  String get sunoApiKey => dotenv.env['SUNO_API_KEY'] ?? '';

  // Validation
  bool get isValid {
    return xaiGrokApiKey.isNotEmpty || openaiApiKey.isNotEmpty;
  }

  // Environment checks
  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isTest => environment == 'test';

  // Voice API validation
  bool get hasGrokApi => xaiGrokApiKey.isNotEmpty;
  bool get hasOpenAIApi => openaiApiKey.isNotEmpty;
  bool get hasWeatherApi => openWeatherApiKey.isNotEmpty;
  bool get hasFirebaseConfig => 
      firebaseProjectId.isNotEmpty && firebaseApiKey.isNotEmpty;

  // Get available voice APIs
  List<String> get availableVoiceApis {
    final apis = <String>[];
    if (hasGrokApi) apis.add('grok');
    if (hasOpenAIApi) apis.add('openai');
    return apis;
  }

  // Get primary API with fallback
  String get effectivePrimaryApi {
    if (primaryVoiceApi == 'grok' && hasGrokApi) return 'grok';
    if (primaryVoiceApi == 'openai' && hasOpenAIApi) return 'openai';
    return availableVoiceApis.firstOrNull ?? 'none';
  }

  String get effectiveFallbackApi {
    if (fallbackVoiceApi == 'grok' && hasGrokApi) return 'grok';
    if (fallbackVoiceApi == 'openai' && hasOpenAIApi) return 'openai';
    return availableVoiceApis.lastOrNull ?? 'none';
  }
} 