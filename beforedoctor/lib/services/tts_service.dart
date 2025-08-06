import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Initialize TTS
  Future<void> initTTS() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      _isInitialized = true;
      print('TTS initialized successfully');
    } catch (e) {
      print('TTS Initialization failed: $e');
      _isInitialized = false;
    }
  }

  // Enhanced speak method with language support
  Future<void> speak(String text, {String languageCode = 'en'}) async {
    if (!_isInitialized) {
      await initTTS();
    }

    try {
      // Set the language for speech output
      await _flutterTts.setLanguage(languageCode);

      // Optional: Adjust pitch, rate, and volume if needed
      await _flutterTts.setPitch(1.0); // 1.0 = normal
      await _flutterTts.setSpeechRate(0.45); // Slower for clarity
      await _flutterTts.setVolume(1.0); // Max volume

      await _flutterTts.speak(text);
      print('🗣️ TTS speaking in $languageCode: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    } catch (e) {
      print("❌ TTS Error: $e");
    }
  }

  // Original speak method (for backward compatibility)
  Future<void> speakText(String text) async {
    if (!_isInitialized) {
      await initTTS();
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Speak error: $e');
    }
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS Stop error: $e');
    }
  }

  // Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('TTS Pause error: $e');
    }
  }

  // Check if TTS is available
  bool get isAvailable => _isInitialized;

  // Get available voices
  Future<List<dynamic>> get voices async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      print('TTS Get voices error: $e');
      return [];
    }
  }

  // Get available languages
  Future<List<dynamic>> get languages async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      print('TTS Get languages error: $e');
      return [];
    }
  }

  // Set language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      print('TTS Set language error: $e');
    }
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('TTS Set speech rate error: $e');
    }
  }

  // Set pitch
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      print('TTS Set pitch error: $e');
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      print('TTS Set volume error: $e');
    }
  }

  // Helper method to map detected language to TTS language code
  String mapToTTSLanguage(String detectedLang) {
    switch (detectedLang) {
      case 'es':
        return 'es-ES'; // Spanish (Spain)
      case 'zh':
        return 'zh-CN'; // Mandarin
      case 'hi':
        return 'hi-IN'; // Hindi
      case 'fr':
        return 'fr-FR'; // French
      case 'de':
        return 'de-DE'; // German
      case 'it':
        return 'it-IT'; // Italian
      case 'pt':
        return 'pt-BR'; // Portuguese (Brazil)
      case 'ja':
        return 'ja-JP'; // Japanese
      case 'ko':
        return 'ko-KR'; // Korean
      case 'ru':
        return 'ru-RU'; // Russian
      case 'ar':
        return 'ar-SA'; // Arabic
      default:
        return 'en-US'; // Fallback to English
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS Dispose error: $e');
    }
  }
} 