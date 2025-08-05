import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

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

  // TTS Controller
  final FlutterTts _tts = FlutterTts();
  
  // Rive Controller
  RiveAnimationController? _characterController;
  Artboard? _artboard;
  
  // Current state
  CharacterState _currentState = CharacterState.idle;
  EmotionalTone _currentTone = EmotionalTone.friendly;
  String _currentLanguage = 'en';
  
  // Callbacks
  Function(String)? onStateChanged;
  Function(double)? onSpeakingProgress;
  Function()? onSpeakingComplete;

  // Initialize the engine
  Future<void> initialize() async {
    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(0.5); // Slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    // Set up TTS callbacks
    _tts.setCompletionHandler(() {
      _setState(CharacterState.idle);
      onSpeakingComplete?.call();
    });
    
    _tts.setProgressHandler((text, start, end, word) {
      final progress = end / text.length;
      onSpeakingProgress?.call(progress);
      _syncLipMovement(word);
    });
  }

  // Set character state
  void setState(CharacterState state) {
    _currentState = state;
    _updateAnimation();
    onStateChanged?.call(state.name);
  }

  // Set emotional tone
  void setEmotionalTone(EmotionalTone tone) {
    _currentTone = tone;
    _updateTTSForTone();
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _tts.setLanguage(languageCode);
  }

  // Speak with animation
  Future<void> speakWithAnimation(String text, {EmotionalTone? tone}) async {
    if (tone != null) {
      setEmotionalTone(tone);
    }
    
    setState(CharacterState.speaking);
    await _tts.speak(text);
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

  // Private methods
  void _setState(CharacterState state) {
    _currentState = state;
    _updateAnimation();
  }

  void _updateAnimation() {
    // Update Rive animation based on state
    switch (_currentState) {
      case CharacterState.idle:
        _characterController?.isActive = false;
        break;
      case CharacterState.listening:
        // Trigger listening animation
        break;
      case CharacterState.speaking:
        // Trigger speaking animation
        break;
      case CharacterState.thinking:
        // Trigger thinking animation
        break;
      case CharacterState.concerned:
        // Trigger concerned animation
        break;
      case CharacterState.happy:
        // Trigger happy animation
        break;
      case CharacterState.explaining:
        // Trigger explaining animation
        break;
    }
  }

  void _updateTTSForTone() {
    switch (_currentTone) {
      case EmotionalTone.friendly:
        _tts.setPitch(1.1);
        _tts.setSpeechRate(0.5);
        break;
      case EmotionalTone.concerned:
        _tts.setPitch(0.9);
        _tts.setSpeechRate(0.4);
        break;
      case EmotionalTone.encouraging:
        _tts.setPitch(1.2);
        _tts.setSpeechRate(0.6);
        break;
      case EmotionalTone.professional:
        _tts.setPitch(1.0);
        _tts.setSpeechRate(0.5);
        break;
      case EmotionalTone.playful:
        _tts.setPitch(1.3);
        _tts.setSpeechRate(0.7);
        break;
      default:
        _tts.setPitch(1.0);
        _tts.setSpeechRate(0.5);
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
    _tts.stop();
    _characterController?.dispose();
  }
} 