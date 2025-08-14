//beforedoctor/lib/services/stt_service.dart
// import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import 'translation_service.dart';

class STTService {
  // final SpeechToText _speech = SpeechToText();
  final TranslationService _translationService = TranslationService();
  
  bool _available = false;
  bool _isInitialized = false;
  bool _isListening = false;
  double _confidence = 0.0;
  String _lastRecognizedText = '';
  String _lastDetectedLanguage = 'en'; // Store detected language
  
  // Stream controllers for real-time updates
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();
  final StreamController<double> _confidenceStreamController = StreamController<double>.broadcast();
  final StreamController<bool> _listeningStreamController = StreamController<bool>.broadcast();
  final StreamController<String> _languageStreamController = StreamController<String>.broadcast(); // New stream for language detection

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return _available;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Microphone permission denied');
        return false;
      }

      // Configure audio session for speech recognition
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Simulate speech recognition availability
      _available = true;
      _isInitialized = true;
      return _available;
    } catch (e) {
      print('STT initialization error: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String text, String detectedLanguage) onResult, // Updated callback to include language
    required Function(String error) onError,
  }) async {
    if (!_available || _isListening) return;

    try {
      _isListening = true;
      _listeningStreamController.add(true);
      
      // Simulate listening with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate recognized text
      final simulatedText = "My child has a fever of 102 degrees";
      _lastRecognizedText = simulatedText;
      _confidence = 0.9;
      
      // Detect language from the simulated text
      try {
        _lastDetectedLanguage = await _translationService.detectLanguage(simulatedText);
        print('🌍 STT detected language: $_lastDetectedLanguage for: "$simulatedText"');
      } catch (e) {
        print('❌ Language detection error: $e');
        _lastDetectedLanguage = 'en'; // Default to English
      }
      
      // Call the callback with both text and detected language
      onResult(simulatedText, _lastDetectedLanguage);
      
      // Update streams
      _textStreamController.add(simulatedText);
      _confidenceStreamController.add(_confidence);
      _languageStreamController.add(_lastDetectedLanguage);
      
      print('Simulated recognition: "$simulatedText" (confidence: ${(_confidence * 100).toStringAsFixed(1)}%, language: $_lastDetectedLanguage)');
      
      _isListening = false;
      _listeningStreamController.add(false);
    } catch (e) {
      print('STT Start error: $e');
      onError(e.toString());
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      // await _speech.stop(); // No longer needed
      _isListening = false;
      _listeningStreamController.add(false);
      print('Stopped listening');
    } catch (e) {
      print('STT Stop error: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      // await _speech.cancel(); // No longer needed
      _isListening = false;
      _listeningStreamController.add(false);
      print('Cancelled listening');
    } catch (e) {
      print('STT Cancel error: $e');
    }
  }

  // Handle speech recognition results with language detection
  void _handleSpeechResult(dynamic result, Function(String text, String detectedLanguage) onResult) async {
    final recognizedWords = result.recognizedWords ?? '';
    _confidence = result.confidence ?? 0.0;
    
    if (recognizedWords.isNotEmpty) {
      _lastRecognizedText = recognizedWords;
      
      // Detect language from the recognized text
      try {
        _lastDetectedLanguage = await _translationService.detectLanguage(recognizedWords);
        print('🌍 STT detected language: $_lastDetectedLanguage for: "$recognizedWords"');
      } catch (e) {
        print('❌ Language detection error: $e');
        _lastDetectedLanguage = 'en'; // Default to English
      }
      
      // Call the callback with both text and detected language
      onResult(recognizedWords, _lastDetectedLanguage);
      
      // Update streams
      _textStreamController.add(recognizedWords);
      _confidenceStreamController.add(_confidence);
      _languageStreamController.add(_lastDetectedLanguage);
      
      print('Recognized: "$recognizedWords" (confidence: ${(_confidence * 100).toStringAsFixed(1)}%, language: $_lastDetectedLanguage)');
    }
  }

  // Handle speech recognition status
  void _handleStatus(String status) {
    switch (status) {
      case 'listening':
        _isListening = true;
        _listeningStreamController.add(true);
        break;
      case 'notListening':
        _isListening = false;
        _listeningStreamController.add(false);
        break;
      case 'done':
        _isListening = false;
        _listeningStreamController.add(false);
        break;
      default:
        print('Speech status: $status');
    }
  }

  // Handle speech recognition errors
  void _handleError(String errorMsg) {
    print('Speech recognition error: $errorMsg');
    _isListening = false;
    _listeningStreamController.add(false);
  }

  // Check if currently listening
  bool get isListening => _isListening;

  // Check if speech recognition is available
  bool get isAvailable => _available;

  // Get confidence level of last recognition
  double get confidence => _confidence;

  // Get last recognized text
  String get lastRecognizedText => _lastRecognizedText;

  // Get last detected language
  String get lastDetectedLanguage => _lastDetectedLanguage;

  // Get text stream
  Stream<String> get textStream => _textStreamController.stream;

  // Get confidence stream
  Stream<double> get confidenceStream => _confidenceStreamController.stream;

  // Get listening status stream
  Stream<bool> get listeningStream => _listeningStreamController.stream;

  // Get language detection stream
  Stream<String> get languageStream => _languageStreamController.stream;

  /// Enhanced method: Listen and detect language in one call
  /// Returns a Map with 'transcript' and 'language' keys
  Future<Map<String, String>> listenAndDetectLanguage() async {
    if (!_available) {
      await initialize();
    }

    final Completer<Map<String, String>> completer = Completer<Map<String, String>>();
    
    try {
      // Simulate listening with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate recognized text
      final simulatedText = "My child has a fever of 102 degrees";
      _lastRecognizedText = simulatedText;
      _confidence = 0.9;
      
      // Detect language from the simulated text
      try {
        _lastDetectedLanguage = await _translationService.detectLanguage(simulatedText);
        print('🌍 STT detected language: $_lastDetectedLanguage for: "$simulatedText"');
      } catch (e) {
        print('❌ Language detection error: $e');
        _lastDetectedLanguage = 'en'; // Default to English
      }
      
      // Update streams
      _textStreamController.add(simulatedText);
      _confidenceStreamController.add(_confidence);
      _languageStreamController.add(_lastDetectedLanguage);
      
      // Complete with result
      if (!completer.isCompleted) {
        completer.complete({
          'transcript': simulatedText,
          'language': _lastDetectedLanguage,
        });
      }
      
      print('Simulated recognition: "$simulatedText" (confidence: ${(_confidence * 100).toStringAsFixed(1)}%, language: $_lastDetectedLanguage)');
      
    } catch (e) {
      print('STT Start error: $e');
      if (!completer.isCompleted) {
        completer.complete({
          'transcript': '',
          'language': 'en',
        });
      }
    }
    
    return completer.future;
  }

  // Check if speech recognition is supported on this device
  Future<bool> get isSupported async {
    // This method is no longer relevant as speech_to_text is removed
    return true;
  }

  // Get available locales
  Future<List<dynamic>> get availableLocales async {
    // This method is no longer relevant as speech_to_text is removed
    return [];
  }

  // Fallback to Google ML Kit for offline recognition (when speech_to_text fails)
  Future<String> recognizeFromAudioFile(String audioFilePath) async {
    try {
      // This would require additional audio processing
      // For now, return empty string as placeholder
      return '';
    } catch (e) {
      print('ML Kit recognition error: $e');
      return '';
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await stopListening();
      await _textStreamController.close();
      await _confidenceStreamController.close();
      await _listeningStreamController.close();
      await _languageStreamController.close();
      _translationService.dispose();
    } catch (e) {
      print('STT Dispose error: $e');
    }
  }
} 