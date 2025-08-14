import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

/// Service for coordinating lip-sync between TTS and Rive animations
class LipSyncService {
  static final LipSyncService _instance = LipSyncService._internal();
  static LipSyncService get instance => _instance;

  LipSyncService._internal();

  final Logger _logger = Logger();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Phoneme mapping for different mouth shapes
  static const Map<String, String> _phonemeMap = {
    // Vowels
    'a': 'mouth_open_a',
    'e': 'mouth_open_e', 
    'i': 'mouth_open_i',
    'o': 'mouth_open_o',
    'u': 'mouth_open_u',
    
    // Consonants that affect mouth shape
    'b': 'mouth_closed',
    'p': 'mouth_closed',
    'm': 'mouth_closed',
    'f': 'mouth_closed',
    'v': 'mouth_closed',
    
    // Open mouth sounds
    'h': 'mouth_open_a',
    'y': 'mouth_open_i',
    'w': 'mouth_open_o',
    
    // Default
    'default': 'mouth_closed',
  };

  // Callback for lip-sync updates
  Function(String)? _onPhonemeChange;
  
  // Current speaking state
  bool _isSpeaking = false;
  Timer? _phonemeTimer;
  
  /// Initialize the lip-sync service
  Future<void> initialize() async {
    try {
      _logger.i('👄 Initializing Lip-Sync Service');
      
      // Configure TTS for phoneme detection
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5); // Slower for better lip-sync
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set up TTS callbacks
      _flutterTts.setStartHandler(() {
        _logger.d('👄 TTS started - beginning lip-sync');
        _isSpeaking = true;
        _startPhonemeSimulation();
      });
      
      _flutterTts.setCompletionHandler(() {
        _logger.d('👄 TTS completed - stopping lip-sync');
        _isSpeaking = false;
        _stopPhonemeSimulation();
      });
      
      _flutterTts.setErrorHandler((msg) {
        _logger.e('❌ TTS error: $msg');
        _isSpeaking = false;
        _stopPhonemeSimulation();
      });

      // Set up progress handler for word-aware lip-sync
      _flutterTts.setProgressHandler((text, start, end, word) {
        if (word != null && word.isNotEmpty) {
          // Compute viseme from the current word
          final phonemes = analyzeTextPhonemes(word);
          if (phonemes.isNotEmpty) {
            final currentPhoneme = phonemes.first;
            _onPhonemeChange?.call(currentPhoneme);
            _logger.d('👄 TTS progress phoneme: $currentPhoneme from word: $word');
          }
        }
      });
      
      _logger.i('👄 Lip-Sync Service initialized successfully');
    } catch (e) {
      _logger.e('❌ Error initializing Lip-Sync Service: $e');
      rethrow;
    }
  }

  /// Set callback for phoneme changes
  void setPhonemeCallback(Function(String) callback) {
    _onPhonemeChange = callback;
  }

  /// Start speaking with lip-sync
  Future<void> speakWithLipSync(String text) async {
    if (_isSpeaking) {
      _logger.w('⚠️ Already speaking, stopping current speech');
      await stopSpeaking();
    }

    try {
      _logger.d('👄 Starting speech with lip-sync: $text');
      await _flutterTts.speak(text);
    } catch (e) {
      _logger.e('❌ Error starting speech: $e');
      rethrow;
    }
  }

  /// Stop speaking and lip-sync
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _stopPhonemeSimulation();
      _logger.d('👄 Speech and lip-sync stopped');
    } catch (e) {
      _logger.e('❌ Error stopping speech: $e');
    }
  }

  /// Start phoneme simulation (fallback when TTS doesn't provide phonemes)
  void _startPhonemeSimulation() {
    if (_phonemeTimer != null) return;
    
    // Simulate phoneme changes every 66ms for smooth lip-sync (~15 Hz)
    _phonemeTimer = Timer.periodic(const Duration(milliseconds: 66), (timer) {
      if (!_isSpeaking) {
        timer.cancel();
        return;
      }
      
      // ENHANCED: Better phoneme simulation based on text analysis
      // Instead of random, use a more natural pattern
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final phonemeIndex = (currentTime / 100) % 6; // 6 basic mouth shapes
      
      String mouthShape;
      switch (phonemeIndex.toInt()) {
        case 0:
          mouthShape = 'mouth_closed';
          break;
        case 1:
          mouthShape = 'mouth_open_a';
          break;
        case 2:
          mouthShape = 'mouth_open_e';
          break;
        case 3:
          mouthShape = 'mouth_open_i';
          break;
        case 4:
          mouthShape = 'mouth_open_o';
          break;
        case 5:
          mouthShape = 'mouth_open_u';
          break;
        default:
          mouthShape = 'mouth_closed';
      }
      
      _onPhonemeChange?.call(mouthShape);
      _logger.d('👄 Simulated phoneme: $mouthShape');
    });
  }

  /// Stop phoneme simulation
  void _stopPhonemeSimulation() {
    _phonemeTimer?.cancel();
    _phonemeTimer = null;
    
    // Signal mouth closed
    _onPhonemeChange?.call('mouth_closed');
  }

  /// Get phoneme for a specific character
  String getPhonemeForCharacter(String character) {
    final lowerChar = character.toLowerCase();
    return _phonemeMap[lowerChar] ?? _phonemeMap['default'] ?? 'mouth_closed';
  }

  /// Analyze text and return phoneme sequence
  List<String> analyzeTextPhonemes(String text) {
    final phonemes = <String>[];
    final words = text.toLowerCase().split(' ');
    
    for (final word in words) {
      for (final char in word.split('')) {
        if (RegExp(r'[a-z]').hasMatch(char)) {
          final phoneme = getPhonemeForCharacter(char);
          phonemes.add(phoneme);
        }
      }
      // Add space between words
      phonemes.add('mouth_closed');
    }
    
    return phonemes;
  }

  /// Get speaking state
  bool get isSpeaking => _isSpeaking;

  /// Configure voice parameters
  Future<void> configureVoice({
    String? languageCode,
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    try {
      if (languageCode != null) await _flutterTts.setLanguage(languageCode);
      if (rate != null) await _flutterTts.setSpeechRate(rate);
      if (pitch != null) await _flutterTts.setPitch(pitch);
      if (volume != null) await _flutterTts.setVolume(volume);
      
      _logger.d('👄 Voice configured: lang=$languageCode, rate=$rate, pitch=$pitch, volume=$volume');
    } catch (e) {
      _logger.e('❌ Error configuring voice: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _stopPhonemeSimulation();
    _flutterTts.stop();
    _onPhonemeChange = null;
    _logger.i('👄 Lip-Sync Service disposed');
  }
}
