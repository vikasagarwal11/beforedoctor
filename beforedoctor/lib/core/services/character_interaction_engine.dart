import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
// REMOVE: import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'lip_sync_service.dart';
import 'rive_animation_manager.dart';

enum CharacterState {
  idle,
  listening,
  speaking,
  thinking,
  concerned,
  happy,
  explaining,
}

enum EmotionalTone {
  neutral,
  friendly,
  concerned,
  encouraging,
  professional,
  playful,
}

class CharacterInteractionEngine {
  static CharacterInteractionEngine? _instance;
  static CharacterInteractionEngine get instance => _instance ??= CharacterInteractionEngine._internal();

  CharacterInteractionEngine._internal();

  // REMOVE: TTS Controller - LipSyncService will own this
  // final FlutterTts _tts = FlutterTts();
  
  // Rive Animation Manager reference
  RiveAnimationManager? _animationManager;
  
  // Current state
  CharacterState _currentState = CharacterState.idle;
  EmotionalTone _currentTone = EmotionalTone.friendly;
  String _currentLanguage = 'en';
  
  // Callbacks
  Function(String)? onStateChanged;
  Function(double)? onSpeakingProgress;
  Function()? onSpeakingComplete;
  
  // ADD THIS: Emotional tone callback
  Function(String)? _onEmotionalToneChanged;
  
  // ADD THIS: Reference to LipSyncService for TTS operations
  static LipSyncService? _lipSyncService;
  
  // Setter methods for callbacks
  void setOnStateChange(Function(String) callback) {
    onStateChanged = callback;
  }
  
  void setOnEmotionalToneChange(Function(String) callback) {
    // STORE the callback instead of doing nothing
    _onEmotionalToneChanged = callback;
  }

  // ADD THIS: Set LipSyncService reference
  static void setLipSyncService(LipSyncService service) {
    _lipSyncService = service;
  }

  // ADD THIS: Set Rive Animation Manager reference
  void setAnimationManager(RiveAnimationManager manager) {
    _animationManager = manager;
  }

  // Initialize the engine
  Future<void> initialize() async {
    // REMOVE: TTS setup - LipSyncService will handle this
    // await _tts.setLanguage(_currentLanguage);
    // await _tts.setSpeechRate(0.5); // Slower for clarity
    // await _tts.setVolume(1.0);
    // await _tts.setPitch(1.0);
    
    // REMOVE: TTS callbacks - LipSyncService will handle these
    // _tts.setCompletionHandler(() {
    //   _setState(CharacterState.idle);
    //   onSpeakingComplete?.call();
    // });
    
    // _tts.setProgressHandler((text, start, end, word) {
    //   final progress = end / text.length;
    //   onSpeakingProgress?.call(progress);
    //   _syncLipMovement(word);
    // });
    
    print('🎭 Character Interaction Engine initialized (TTS delegated to LipSyncService)');
  }

  // Set character state
  void setState(CharacterState state) {
    _currentState = state;
    _updateAnimation();
    onStateChanged?.call(state.name);
  }

  // Change character state (public method for external use)
  Future<void> changeState(String stateName) async {
    try {
      final state = CharacterState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => CharacterState.idle,
      );
      setState(state);
    } catch (e) {
      print('Error changing state to $stateName: $e');
    }
  }

  // Set emotional tone
  void setEmotionalTone(EmotionalTone tone) {
    _currentTone = tone;
    _updateTTSForTone();
    // FIRE the callback so UI/notifier can react
    _onEmotionalToneChanged?.call(tone.name);
  }

  // Change emotional tone (public method for external use)
  Future<void> changeEmotionalTone(String toneName) async {
    try {
      final tone = EmotionalTone.values.firstWhere(
        (t) => t.name == toneName,
        orElse: () => EmotionalTone.neutral,
      );
      setEmotionalTone(tone);
    } catch (e) {
      print('Error changing emotional tone to $toneName: $e');
    }
  }

  // (optional quality-of-life)
  EmotionalTone get currentTone => _currentTone;

  // Set language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    // await _tts.setLanguage(languageCode); // This line is removed as TTS is now delegated
    print('🗣️ Character TTS language set to: $languageCode');
  }

  // Speak with animation - Updated to delegate to LipSyncService
  Future<void> speakWithAnimation(String text, {EmotionalTone? tone, String? detectedLanguage}) async {
    if (tone != null) {
      setEmotionalTone(tone);
    }
    
    // Set language for TTS if detected language is provided
    if (detectedLanguage != null && detectedLanguage != _currentLanguage) {
      await setLanguage(detectedLanguage);
    }
    
    setState(CharacterState.speaking);
    print('🗣️ Character speaking in $_currentLanguage: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    
    // DELEGATE to LipSyncService instead of using local TTS
    if (_lipSyncService != null) {
      await _lipSyncService!.speakWithLipSync(text);
    } else {
      print('⚠️ Warning: LipSyncService not set, speech will not work');
    }
  }

  // Listen mode
  void startListening() {
    setState(CharacterState.listening);
  }

  // Thinking mode
  void startThinking() {
    setState(CharacterState.thinking);
  }

  // React to symptoms
  void reactToSymptom(String symptom) {
    if (symptom.toLowerCase().contains('fever') || 
        symptom.toLowerCase().contains('pain') ||
        symptom.toLowerCase().contains('hurt')) {
      setState(CharacterState.concerned);
      setEmotionalTone(EmotionalTone.concerned);
    } else if (symptom.toLowerCase().contains('better') ||
               symptom.toLowerCase().contains('good')) {
      setState(CharacterState.happy);
      setEmotionalTone(EmotionalTone.encouraging);
    } else {
      setState(CharacterState.explaining);
      setEmotionalTone(EmotionalTone.professional);
    }
  }

  // Get localized greeting
  String getLocalizedGreeting() {
    switch (_currentLanguage) {
      case 'es':
        return '¡Hola! Soy el Dr. BeforeDoctor. ¿Cómo puedo ayudarte hoy?';
      case 'zh':
        return '你好！我是BeforeDoctor医生。今天我能为您做些什么？';
      case 'fr':
        return 'Bonjour ! Je suis le Dr. BeforeDoctor. Comment puis-je vous aider aujourd\'hui ?';
      case 'hi':
        return 'नमस्ते! मैं डॉ. BeforeDoctor हूं। आज मैं आपकी कैसे मदद कर सकता हूं?';
      default:
        return 'Hello! I\'m Dr. BeforeDoctor. How can I help you today?';
    }
  }

  // Get localized symptom prompt
  String getLocalizedSymptomPrompt() {
    switch (_currentLanguage) {
      case 'es':
        return 'Por favor, cuéntame sobre los síntomas.';
      case 'zh':
        return '请告诉我症状。';
      case 'fr':
        return 'S\'il vous plaît, parlez-moi des symptômes.';
      case 'hi':
        return 'कृपया मुझे लक्षणों के बारे में बताएं।';
      default:
        return 'Please tell me about the symptoms.';
    }
  }

  // Get current language
  String get currentLanguage => _currentLanguage;

  // Private methods
  void _setState(CharacterState state) {
    _currentState = state;
    _updateAnimation();
  }

  void _updateAnimation() {
    // Update Rive animation based on state
    if (_animationManager == null) {
      print('⚠️ Animation manager not set, cannot update animation');
      return;
    }

    final stateName = _currentState.name;
    print('🎭 Updating animation to: $stateName');
    
    try {
      _animationManager!.playAnimation(stateName);
    } catch (e) {
      print('❌ Error playing animation $stateName: $e');
    }
  }

  void _updateTTSForTone() {
    // Configure voice based on emotional tone via LipSyncService
    if (_lipSyncService == null) {
      print('⚠️ Warning: LipSyncService not set, cannot configure voice for tone');
      return;
    }

    try {
      switch (_currentTone) {
        case EmotionalTone.friendly:
          _lipSyncService!.configureVoice(pitch: 1.1, rate: 0.5);
          break;
        case EmotionalTone.concerned:
          _lipSyncService!.configureVoice(pitch: 0.9, rate: 0.4);
          break;
        case EmotionalTone.encouraging:
          _lipSyncService!.configureVoice(pitch: 1.2, rate: 0.6);
          break;
        case EmotionalTone.professional:
          _lipSyncService!.configureVoice(pitch: 1.0, rate: 0.5);
          break;
        case EmotionalTone.playful:
          _lipSyncService!.configureVoice(pitch: 1.3, rate: 0.7);
          break;
        default:
          _lipSyncService!.configureVoice(pitch: 1.0, rate: 0.5);
      }
      print('🎭 Voice configured for tone: ${_currentTone.name}');
    } catch (e) {
      print('❌ Error configuring voice for tone: $e');
    }
  }

  void _syncLipMovement(String word) {
    // Map phonemes to lip-sync animations
    if (word.contains('a') || word.contains('o')) {
      // Open mouth animation
    } else if (word.contains('e') || word.contains('i')) {
      // Smile mouth animation
    } else if (word.contains('u')) {
      // Round mouth animation
    }
  }

  // Dispose resources
  void dispose() {
    // _tts.stop(); // This line is removed as TTS is now delegated
    // Animation manager will handle its own disposal
    print('🎭 Character Interaction Engine disposed');
  }
} 