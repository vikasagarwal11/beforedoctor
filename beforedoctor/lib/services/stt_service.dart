import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';

class STTService {
  final SpeechToText _speech = SpeechToText();
  
  bool _available = false;
  bool _isInitialized = false;
  bool _isListening = false;
  double _confidence = 0.0;
  String _lastRecognizedText = '';
  
  // Stream controllers for real-time updates
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();
  final StreamController<double> _confidenceStreamController = StreamController<double>.broadcast();
  final StreamController<bool> _listeningStreamController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<String> get textStream => _textStreamController.stream;
  Stream<double> get confidenceStream => _confidenceStreamController.stream;
  Stream<bool> get listeningStream => _listeningStreamController.stream;

  // Initialize the service with proper permissions and audio session
  Future<bool> initialize() async {
    try {
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

      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        print('Microphone permission denied');
        _available = false;
        return false;
      }

      // Initialize speech recognition
      _available = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: ${error.errorMsg}');
          _handleError(error.errorMsg);
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          _handleStatus(status);
        },
        debugLogging: true,
      );

      if (_available) {
        _isInitialized = true;
        print('Speech recognition initialized successfully');
        return true;
      } else {
        print('Speech recognition not available');
        return false;
      }
    } catch (e) {
      print('STT Initialization failed: $e');
      _available = false;
      return false;
    }
  }

  // Start listening with real-time results
  Future<void> startListening({
    required Function(String text) onResult,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (!_available) {
      onError?.call('Speech recognition not available');
      return;
    }

    if (_isListening) {
      onError?.call('Already listening');
      return;
    }

    try {
      // Configure speech recognition
      await _speech.listen(
        onResult: (result) {
          _handleSpeechResult(result, onResult);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US', // Can be made configurable
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      _listeningStreamController.add(true);
      print('Started listening for speech');
    } catch (e) {
      print('STT Listen error: $e');
      onError?.call('Failed to start listening: $e');
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        _listeningStreamController.add(false);
        print('Stopped listening');
      }
    } catch (e) {
      print('STT Stop error: $e');
    }
  }

  // Cancel listening
  Future<void> cancelListening() async {
    try {
      if (_isListening) {
        await _speech.cancel();
        _isListening = false;
        _listeningStreamController.add(false);
        print('Cancelled listening');
      }
    } catch (e) {
      print('STT Cancel error: $e');
    }
  }

  // Handle speech recognition results
  void _handleSpeechResult(SpeechRecognitionResult result, Function(String text) onResult) {
    final recognizedWords = result.recognizedWords;
    _confidence = result.confidence;
    
    if (recognizedWords.isNotEmpty) {
      _lastRecognizedText = recognizedWords;
      onResult(recognizedWords);
      _textStreamController.add(recognizedWords);
      _confidenceStreamController.add(_confidence);
      
      print('Recognized: "$recognizedWords" (confidence: ${(_confidence * 100).toStringAsFixed(1)}%)');
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

  // Check if speech recognition is supported on this device
  Future<bool> get isSupported async {
    return await _speech.initialize(
      onError: (error) => print('Error: ${error.errorMsg}'),
      onStatus: (status) => print('Status: $status'),
    );
  }

  // Get available locales
  Future<List<LocaleName>> get availableLocales async {
    return await _speech.locales();
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
    } catch (e) {
      print('STT Dispose error: $e');
    }
  }
} 