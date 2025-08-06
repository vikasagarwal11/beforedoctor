import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class TranslationService {
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  final Map<String, OnDeviceTranslator> _translators = {};
  bool _isDisposed = false;

  /// Detects the language of the input text
  Future<String> detectLanguage(String text) async {
    if (_isDisposed) return 'en';
    
    try {
      final String language = await _languageIdentifier.identifyLanguage(text);
      print('🌍 Detected language: $language for text: "${text.substring(0, text.length > 20 ? 20 : text.length)}..."');
      return language;
    } catch (e) {
      print('❌ Error detecting language: $e');
      return 'en'; // Default to English
    }
  }

  /// Ensures the required language model is downloaded
  Future<void> ensureModelDownloaded(String languageCode) async {
    if (_isDisposed) return;
    
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      final isDownloaded = await modelManager.isModelDownloaded(languageCode);
      
      if (!isDownloaded) {
        print('📥 Downloading translation model for: $languageCode');
        await modelManager.downloadModel(languageCode);
        print('✅ Translation model downloaded for: $languageCode');
      } else {
        print('✅ Translation model already available for: $languageCode');
      }
    } catch (e) {
      print('❌ Error downloading translation model for $languageCode: $e');
    }
  }

  /// Translates text from one language to another
  Future<String> translateText({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    if (_isDisposed) return text;
    
    try {
      // Ensure both language models are downloaded
      await ensureModelDownloaded(fromLang);
      await ensureModelDownloaded(toLang);

      final key = '$fromLang-$toLang';
      
      // Create or reuse translator
      if (!_translators.containsKey(key)) {
        _translators[key] = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.values.firstWhere(
            (lang) => lang.name == fromLang,
            orElse: () => TranslateLanguage.english,
          ),
          targetLanguage: TranslateLanguage.values.firstWhere(
            (lang) => lang.name == toLang,
            orElse: () => TranslateLanguage.english,
          ),
        );
        print('🔧 Created translator: $fromLang → $toLang');
      }

      // Perform translation
      final translatedText = await _translators[key]!.translateText(text);
      print('🌍 Translated: "${text.substring(0, text.length > 30 ? 30 : text.length)}..." → "${translatedText.substring(0, translatedText.length > 30 ? 30 : translatedText.length)}..."');
      
      return translatedText;
    } catch (e) {
      print('❌ Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  /// Translates AI responses to the user's preferred language
  Future<String> translateAIResponse({
    required String aiResponse,
    required String userLanguage,
  }) async {
    if (userLanguage == 'en') return aiResponse; // No translation needed
    
    return await translateText(
      text: aiResponse,
      fromLang: 'en',
      toLang: userLanguage,
    );
  }

  /// Translates user input to English for AI processing
  Future<String> translateUserInput({
    required String userInput,
    required String userLanguage,
  }) async {
    if (userLanguage == 'en') return userInput; // No translation needed
    
    return await translateText(
      text: userInput,
      fromLang: userLanguage,
      toLang: 'en',
    );
  }

  /// Gets supported languages for the app
  List<String> getSupportedLanguages() {
    return [
      'en', // English
      'es', // Spanish
      'zh', // Chinese
      'fr', // French
      'de', // German
      'it', // Italian
      'pt', // Portuguese
      'ru', // Russian
      'ja', // Japanese
      'ko', // Korean
    ];
  }

  /// Gets language display names
  Map<String, String> getLanguageDisplayNames() {
    return {
      'en': 'English',
      'es': 'Español',
      'zh': '中文',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'ja': '日本語',
      'ko': '한국어',
    };
  }

  /// Checks if a language is supported
  bool isLanguageSupported(String languageCode) {
    return getSupportedLanguages().contains(languageCode);
  }

  /// Gets the display name for a language code
  String getLanguageDisplayName(String languageCode) {
    return getLanguageDisplayNames()[languageCode] ?? languageCode.toUpperCase();
  }

  /// Pre-downloads common language models for better performance
  Future<void> preloadCommonLanguages() async {
    if (_isDisposed) return;
    
    final commonLanguages = ['en', 'es', 'zh', 'fr'];
    
    print('📥 Preloading common language models...');
    for (final lang in commonLanguages) {
      await ensureModelDownloaded(lang);
    }
    print('✅ Common language models preloaded');
  }

  /// Disposes resources
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
    
    _languageIdentifier.close();
    
    print('🧹 Translation service disposed');
  }
} 