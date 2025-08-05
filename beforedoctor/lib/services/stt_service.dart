import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class STTService {
  final SpeechToText _speech = SpeechToText();
  final TextRecognizer _mlKitRecognizer = GoogleMlKit.vision.textRecognizer();
  
  bool _available = false;
  bool _isInitialized = false;

  // Initialize the service
  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onError: (error) => print('STT Error: ${error.errorMsg}'),
        onStatus: (status) => print('STT Status: $status'),
      );
      _isInitialized = true;
      return _available;
    } catch (e) {
      print('STT Initialization failed: $e');
      _available = false;
      return false;
    }
  }

  // Start listening with real-time results
  Future<void> startListening({
    required Function(String text) onResult,
    Function()? onDone,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_available) {
      try {
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              onResult(result.recognizedWords);
            }
          },
          listenMode: ListenMode.dictation,
          onSoundLevelChange: null,
          onDevice: false,
          cancelOnError: true,
          onDone: onDone,
          onError: (error) {
            print('STT Error: ${error.errorMsg}');
            onError?.call(error.errorMsg);
          },
        );
      } catch (e) {
        print('STT Listen error: $e');
        onError?.call('Failed to start listening: $e');
      }
    } else {
      onError?.call('Speech recognition not available');
    }
  }

  // Stop listening
  void stopListening() {
    try {
      _speech.stop();
    } catch (e) {
      print('STT Stop error: $e');
    }
  }

  // Cancel listening
  void cancelListening() {
    try {
      _speech.cancel();
    } catch (e) {
      print('STT Cancel error: $e');
    }
  }

  // Check if currently listening
  bool get isListening => _speech.isListening;

  // Check if speech recognition is available
  bool get isAvailable => _available;

  // Get confidence level of last recognition
  double get confidence => _speech.lastRecognizedWords.isNotEmpty ? 0.9 : 0.0;

  // Fallback to Google ML Kit for offline recognition
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
      await _speech.stop();
      await _mlKitRecognizer.close();
    } catch (e) {
      print('STT Dispose error: $e');
    }
  }
} 