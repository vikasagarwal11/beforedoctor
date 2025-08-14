import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:beforedoctor/core/services/character_animation_controller.dart';

/// Advanced lip-sync controller for character speech
/// Provides real-time synchronization between TTS and character animations
class CharacterLipSyncController {
  static CharacterLipSyncController? _instance;
  static CharacterLipSyncController get instance => _instance ??= CharacterLipSyncController._internal();

  CharacterLipSyncController._internal();

  // Core services
  final FlutterTts _tts = FlutterTts();
  final CharacterAnimationController _animationController = CharacterAnimationController.instance;
  
  // Lip-sync state
  bool _isLipSyncing = false;
  bool _isPaused = false;
  String _currentText = '';
  int _currentWordIndex = 0;
  
  // Phoneme analysis
  final Map<String, String> _phonemeMap = {
    'a': 'open_mouth',
    'e': 'smile_mouth',
    'i': 'smile_mouth',
    'o': 'round_mouth',
    'u': 'round_mouth',
    'y': 'smile_mouth',
    'b': 'closed_mouth',
    'p': 'closed_mouth',
    'm': 'closed_mouth',
    'f': 'lower_lip',
    'v': 'lower_lip',
    'th': 'tongue_out',
    's': 'hiss_mouth',
    'z': 'hiss_mouth',
    'sh': 'hiss_mouth',
    'ch': 'hiss_mouth',
    'j': 'hiss_mouth',
    'l': 'tongue_up',
    'r': 'tongue_up',
    'n': 'tongue_up',
    't': 'tongue_up',
    'd': 'tongue_up',
    'k': 'tongue_back',
    'g': 'tongue_back',
    'h': 'breath_mouth',
    'w': 'round_mouth',
    'q': 'round_mouth',
  };
  
  // Timing configuration
  static const Duration _defaultPhonemeDuration = Duration(milliseconds: 150);
  static const Duration _minPhonemeDuration = Duration(milliseconds: 100);
  static const Duration _maxPhonemeDuration = Duration(milliseconds: 300);
  
  // Callbacks
  Function(String)? onPhonemeChanged;
  Function(double)? onLipSyncProgress;
  Function()? onLipSyncComplete;
  Function(String)? onLipSyncError;

  /// Initialize the lip-sync controller
  Future<void> initialize() async {
    try {
      // Set up TTS callbacks for lip-sync
      _tts.setProgressHandler((text, start, end, word) {
        _handleWordProgress(text, start, end, word);
      });
      
      _tts.setCompletionHandler(() {
        _handleSpeechComplete();
      });
      
      _tts.setErrorHandler((msg) {
        _handleTTSError(msg);
      });
      
      print('🎭 Lip-sync Controller initialized');
    } catch (e) {
      print('❌ Error initializing Lip-sync Controller: $e');
    }
  }

  /// Start lip-sync with text
  Future<void> startLipSync(String text, {Duration? phonemeDuration}) async {
    if (_isLipSyncing) {
      await stopLipSync();
    }
    
    _currentText = text;
    _currentWordIndex = 0;
    _isLipSyncing = true;
    _isPaused = false;
    
    try {
      // Start speaking with TTS
      await _tts.speak(text);
      
      // Start lip-sync animation
      await _animationController.startLipSync();
      
      print('🎭 Lip-sync started for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    } catch (e) {
      print('❌ Error starting lip-sync: $e');
      _handleLipSyncError('Failed to start lip-sync: $e');
    }
  }

  /// Stop lip-sync
  Future<void> stopLipSync() async {
    if (!_isLipSyncing) return;
    
    _isLipSyncing = false;
    _isPaused = false;
    
    try {
      // Stop TTS
      await _tts.stop();
      
      // Stop lip-sync animation
      await _animationController.stopLipSync();
      
      // Reset state
      _currentText = '';
      _currentWordIndex = 0;
      
      print('🎭 Lip-sync stopped');
      onLipSyncComplete?.call();
    } catch (e) {
      print('❌ Error stopping lip-sync: $e');
    }
  }

  /// Pause lip-sync
  Future<void> pauseLipSync() async {
    if (!_isLipSyncing || _isPaused) return;
    
    _isPaused = true;
    
    try {
      await _tts.pause();
      print('🎭 Lip-sync paused');
    } catch (e) {
      print('❌ Error pausing lip-sync: $e');
    }
  }

  /// Resume lip-sync
  Future<void> resumeLipSync() async {
    if (!_isLipSyncing || !_isPaused) return;
    
    _isPaused = false;
    
    try {
      await _tts.resume();
      print('🎭 Lip-sync resumed');
    } catch (e) {
      print('❌ Error resuming lip-sync: $e');
    }
  }

  /// Handle word progress from TTS
  void _handleWordProgress(String text, int start, int end, String word) {
    if (!_isLipSyncing || _isPaused) return;
    
    // Calculate progress
    final progress = end / text.length;
    onLipSyncProgress?.call(progress);
    
    // Analyze word for phonemes
    _analyzeWordForLipSync(word);
    
    // Update word index
    _currentWordIndex++;
  }

  /// Analyze word and trigger appropriate lip-sync
  void _analyzeWordForLipSync(String word) {
    if (word.isEmpty) return;
    
    // Convert to lowercase for phoneme matching
    final lowerWord = word.toLowerCase();
    
    // Find the most prominent phoneme in the word
    final phoneme = _findProminentPhoneme(lowerWord);
    
    if (phoneme != null) {
      // Trigger lip-sync animation
      _triggerLipSyncAnimation(phoneme);
      
      // Notify listeners
      onPhonemeChanged?.call(phoneme);
      
      print('🎭 Lip-sync: "$word" -> $phoneme');
    }
  }

  /// Find the most prominent phoneme in a word
  String? _findProminentPhoneme(String word) {
    // Priority order for phoneme detection
    final priorityPhonemes = ['th', 'sh', 'ch', 'ph', 'wh'];
    
    // Check for priority phonemes first
    for (final phoneme in priorityPhonemes) {
      if (word.contains(phoneme)) {
        return _phonemeMap[phoneme];
      }
    }
    
    // Check for vowel sounds (most important for lip-sync)
    final vowels = ['a', 'e', 'i', 'o', 'u', 'y'];
    for (final vowel in vowels) {
      if (word.contains(vowel)) {
        return _phonemeMap[vowel];
      }
    }
    
    // Check for consonant sounds
    for (final entry in _phonemeMap.entries) {
      if (word.contains(entry.key) && !priorityPhonemes.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Trigger lip-sync animation
  void _triggerLipSyncAnimation(String phoneme) {
    try {
      // Map phoneme to animation gesture
      final animationType = _mapPhonemeToAnimation(phoneme);
      
      // Play the animation
      _animationController.playGesture(animationType);
      
    } catch (e) {
      print('❌ Error triggering lip-sync animation: $e');
    }
  }

  /// Map phoneme to animation type
  String _mapPhonemeToAnimation(String phoneme) {
    switch (phoneme) {
      case 'open_mouth':
        return 'mouth_open';
      case 'smile_mouth':
        return 'mouth_smile';
      case 'round_mouth':
        return 'mouth_round';
      case 'closed_mouth':
        return 'mouth_closed';
      case 'lower_lip':
        return 'mouth_lower_lip';
      case 'tongue_out':
        return 'mouth_tongue_out';
      case 'hiss_mouth':
        return 'mouth_hiss';
      case 'tongue_up':
        return 'mouth_tongue_up';
      case 'tongue_back':
        return 'mouth_tongue_back';
      case 'breath_mouth':
        return 'mouth_breath';
      default:
        return 'mouth_neutral';
    }
  }

  /// Handle speech completion
  void _handleSpeechComplete() {
    _isLipSyncing = false;
    _isPaused = false;
    
    // Stop lip-sync animation
    _animationController.stopLipSync();
    
    // Reset state
    _currentText = '';
    _currentWordIndex = 0;
    
    print('🎭 Lip-sync completed');
    onLipSyncComplete?.call();
  }

  /// Handle TTS errors
  void _handleTTSError(String error) {
    print('❌ TTS Error: $error');
    _handleLipSyncError('TTS error: $error');
  }

  /// Handle lip-sync errors
  void _handleLipSyncError(String error) {
    _isLipSyncing = false;
    _isPaused = false;
    
    // Stop animations
    _animationController.stopLipSync();
    
    // Reset state
    _currentText = '';
    _currentWordIndex = 0;
    
    onLipSyncError?.call(error);
  }

  /// Get current lip-sync status
  Map<String, dynamic> getLipSyncStatus() {
    return {
      'is_lip_syncing': _isLipSyncing,
      'is_paused': _isPaused,
      'current_text': _currentText,
      'current_word_index': _currentWordIndex,
      'total_words': _currentText.split(' ').length,
      'progress': _currentWordIndex / (_currentText.split(' ').length > 0 ? _currentText.split(' ').length : 1),
    };
  }

  /// Set custom phoneme mapping
  void setCustomPhonemeMapping(String phoneme, String animation) {
    _phonemeMap[phoneme.toLowerCase()] = animation;
    print('🎭 Custom phoneme mapping: $phoneme -> $animation');
  }

  /// Get all available phonemes
  List<String> getAvailablePhonemes() {
    return _phonemeMap.values.toSet().toList();
  }

  /// Test lip-sync with specific phoneme
  Future<void> testPhoneme(String phoneme) async {
    try {
      await _animationController.playGesture(_mapPhonemeToAnimation(phoneme));
      print('🎭 Testing phoneme: $phoneme');
    } catch (e) {
      print('❌ Error testing phoneme: $e');
    }
  }

  /// Get lip-sync performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'phoneme_count': _phonemeMap.length,
      'custom_mappings': _phonemeMap.length - 26, // Assuming 26 basic English letters
      'is_active': _isLipSyncing,
      'current_state': _isPaused ? 'paused' : (_isLipSyncing ? 'active' : 'inactive'),
    };
  }

  // Getters
  bool get isLipSyncing => _isLipSyncing;
  bool get isPaused => _isPaused;
  String get currentText => _currentText;
  int get currentWordIndex => _currentWordIndex;

  /// Dispose resources
  void dispose() {
    _tts.stop();
    _animationController.stopLipSync();
    
    _currentText = '';
    _currentWordIndex = 0;
    _isLipSyncing = false;
    _isPaused = false;
    
    print('🎭 Character Lip-sync Controller disposed');
  }
}
