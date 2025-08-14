import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._internal();

  AppConfig._internal();

  // Voice API Endpoints
  String get openaiApiEndpoint => dotenv.env['OPENAI_API_ENDPOINT'] ?? 'https://api.openai.com/v1/chat/completions';
  String get xaiGrokApiEndpoint => dotenv.env['XAI_GROK_API_ENDPOINT'] ?? 'https://api.x.ai/v1/chat/completions';

  // Voice APIs
  String get xaiGrokApiKey => dotenv.env['XAI_GROK_API_KEY'] ?? '';
  String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // Model Configurations
  String get openaiModel => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o';
  String get xaiGrokModel => dotenv.env['XAI_GROK_MODEL'] ?? 'grok-beta';
  double get openaiTemperature => double.tryParse(dotenv.env['OPENAI_TEMPERATURE'] ?? '0.7') ?? 0.7;
  double get xaiGrokTemperature => double.tryParse(dotenv.env['XAI_GROK_TEMPERATURE'] ?? '0.7') ?? 0.7;

  // API Timeouts
  int get openaiTimeout => int.tryParse(dotenv.env['OPENAI_TIMEOUT'] ?? '30') ?? 30;
  int get xaiGrokTimeout => int.tryParse(dotenv.env['XAI_GROK_TIMEOUT'] ?? '30') ?? 30;
  int get openWeatherTimeout => int.tryParse(dotenv.env['OPENWEATHER_TIMEOUT'] ?? '10') ?? 10;

  // Weather API
  String get openWeatherApiEndpoint => dotenv.env['OPENWEATHER_API_ENDPOINT'] ?? 'https://api.openweathermap.org/data/2.5/weather';
  String get openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  // ML Kit API
  String get mlKitApiKey => dotenv.env['ML_KIT_API_KEY'] ?? '';

  // Firebase Configuration
  String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  String get firebaseDatabaseUrl => dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
  String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  String get firebaseMeasurementId => dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  // App Configuration
  String get appName => dotenv.env['APP_NAME'] ?? 'BeforeDoctor';
  String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';

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
  bool get hasMlKitApi => mlKitApiKey.isNotEmpty;

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