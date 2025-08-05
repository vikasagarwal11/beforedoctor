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
    } catch (e) {
      print('TTS Initialization failed: $e');
      _isInitialized = false;
    }
  }

  // Speak text
  Future<void> speak(String text) async {
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

  // Resume speaking
  Future<void> resume() async {
    try {
      await _flutterTts.resume();
    } catch (e) {
      print('TTS Resume error: $e');
    }
  }

  // Check if TTS is available
  bool get isAvailable => _isInitialized;

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS Dispose error: $e');
    }
  }
} 