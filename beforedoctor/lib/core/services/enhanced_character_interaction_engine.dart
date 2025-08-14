import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:beforedoctor/core/services/character_animation_controller.dart';
import 'package:beforedoctor/core/services/character_animation_assets.dart';

/// Enhanced character interaction engine with advanced animation control
/// Integrates TTS, Rive animations, and intelligent character behavior
class EnhancedCharacterInteractionEngine {
  static EnhancedCharacterInteractionEngine? _instance;
  static EnhancedCharacterInteractionEngine get instance => _instance ??= EnhancedCharacterInteractionEngine._internal();

  EnhancedCharacterInteractionEngine._internal();

  // Core services
  final FlutterTts _tts = FlutterTts();
  final CharacterAnimationController _animationController = CharacterAnimationController.instance;
  
  // Character state management
  CharacterState _currentState = CharacterState.idle;
  EmotionalTone _currentTone = EmotionalTone.friendly;
  String _currentLanguage = 'en';
  
  // Advanced behavior tracking
  final Map<String, int> _symptomFrequency = {};
  final List<String> _conversationHistory = [];
  bool _isFirstInteraction = true;
  
  // Callbacks
  Function(String)? onStateChanged;
  Function(double)? onSpeakingProgress;
  Function()? onSpeakingComplete;
  Function(String)? onAnimationChanged;
  Function(String)? onEmotionalResponse;

  /// Initialize the enhanced engine
  Future<void> initialize() async {
    try {
      // Initialize TTS
      await _initializeTTS();
      
      // Initialize animation controller
      await _animationController.initialize();
      
      // Set up animation callbacks
      _animationController.onAnimationChanged = (state) {
        onAnimationChanged?.call(state);
      };
      
      _animationController.onStateTransition = (state) {
        onStateChanged?.call(state);
      };
      
      print('🎭 Enhanced Character Interaction Engine initialized');
    } catch (e) {
      print('❌ Error initializing Enhanced Character Engine: $e');
    }
  }

  /// Initialize TTS with enhanced settings
  Future<void> _initializeTTS() async {
    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    // Enhanced TTS callbacks
    _tts.setCompletionHandler(() {
      _handleSpeakingComplete();
    });
    
    _tts.setProgressHandler((text, start, end, word) {
      final progress = end / text.length;
      onSpeakingProgress?.call(progress);
      _handleLipSync(word);
    });
    
    _tts.setErrorHandler((msg) {
      print('❌ TTS Error: $msg');
      _handleTTSError();
    });
  }

  /// Enhanced state management with emotional intelligence
  void setState(CharacterState state, {EmotionalTone? tone, Duration? transitionDuration}) {
    _currentState = state;
    
    if (tone != null) {
      _currentTone = tone;
    }
    
    // Update animation with smooth transition
    _animationController.changeState(state.name, transitionDuration: transitionDuration);
    
    // Update TTS for new tone
    _updateTTSForTone();
    
    onStateChanged?.call(state.name);
    
    // Log state change for behavior analysis
    _logStateChange(state, tone);
  }

  /// Set emotional tone with animation feedback
  void setEmotionalTone(EmotionalTone tone) {
    _currentTone = tone;
    _updateTTSForTone();
    
    // Trigger emotional response animation
    _triggerEmotionalResponse(tone);
    
    onEmotionalResponse?.call(tone.name);
  }

  /// Enhanced language setting with cultural adaptation
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _tts.setLanguage(languageCode);
    
    // Adapt character behavior for culture
    _adaptToCulture(languageCode);
    
    print('🗣️ Character adapted to language: $languageCode');
  }

  /// Intelligent symptom reaction with context awareness
  void reactToSymptom(String symptom, {String? context, int? severity}) {
    // Track symptom frequency
    _symptomFrequency[symptom.toLowerCase()] = 
        (_symptomFrequency[symptom.toLowerCase()] ?? 0) + 1;
    
    // Analyze symptom context
    final analysis = _analyzeSymptom(symptom, context, severity);
    
    // Set appropriate state and tone
    setState(analysis.state, tone: analysis.tone);
    
    // Log for medical insights
    _logSymptomReaction(symptom, analysis);
  }

  /// Enhanced speaking with animation synchronization
  Future<void> speakWithAnimation(
    String text, {
    EmotionalTone? tone,
    String? detectedLanguage,
    bool enableLipSync = true,
    Duration? animationDuration,
  }) async {
    if (tone != null) {
      setEmotionalTone(tone);
    }
    
    // Set language if detected
    if (detectedLanguage != null && detectedLanguage != _currentLanguage) {
      await setLanguage(detectedLanguage);
    }
    
    // Start speaking state
    setState(CharacterState.speaking, transitionDuration: animationDuration);
    
    // Start lip sync if enabled
    if (enableLipSync) {
      await _animationController.startLipSync();
    }
    
    // Speak with TTS
    print('🗣️ Character speaking in $_currentLanguage: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    await _tts.speak(text);
    
    // Log conversation
    _logConversation(text, 'character_speech');
  }

  /// Intelligent listening mode with context awareness
  void startListening({String? expectedInput, Duration? timeout}) {
    setState(CharacterState.listening);
    
    // Set up listening timeout if specified
    if (timeout != null) {
      Future.delayed(timeout, () {
        if (_currentState == CharacterState.listening) {
          _handleListeningTimeout();
        }
      });
    }
    
    // Log listening session
    _logConversation('Started listening', 'listening_start');
  }

  /// Enhanced thinking mode with visual feedback
  void startThinking({String? context, Duration? duration}) {
    setState(CharacterState.thinking);
    
    // Trigger thinking animation
    _animationController.changeState('thinking');
    
    // Set thinking duration
    if (duration != null) {
      Future.delayed(duration, () {
        if (_currentState == CharacterState.thinking) {
          _handleThinkingComplete();
        }
      });
    }
  }

  /// Get contextual greeting based on time and history
  String getContextualGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    String timeBasedGreeting;
    if (hour < 12) {
      timeBasedGreeting = 'Good morning';
    } else if (hour < 17) {
      timeBasedGreeting = 'Good afternoon';
    } else {
      timeBasedGreeting = 'Good evening';
    }
    
    if (_isFirstInteraction) {
      _isFirstInteraction = false;
      return _getLocalizedGreeting(timeBasedGreeting);
    } else {
      return _getLocalizedGreeting('Welcome back');
    }
  }

  /// Get intelligent symptom prompt based on conversation history
  String getIntelligentSymptomPrompt() {
    if (_symptomFrequency.isEmpty) {
      return _getLocalizedSymptomPrompt('general');
    }
    
    // Find most common symptom
    final mostCommon = _symptomFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return _getLocalizedSymptomPrompt('follow_up', symptom: mostCommon.key);
  }

  /// Get character behavior insights
  Map<String, dynamic> getBehaviorInsights() {
    return {
      'total_interactions': _conversationHistory.length,
      'symptom_frequency': Map.from(_symptomFrequency),
      'preferred_language': _currentLanguage,
      'emotional_tendencies': _analyzeEmotionalTendencies(),
      'conversation_patterns': _analyzeConversationPatterns(),
    };
  }

  // Private helper methods

  void _handleSpeakingComplete() {
    _animationController.stopLipSync();
    setState(CharacterState.idle);
    onSpeakingComplete?.call();
  }

  void _handleLipSync(String word) {
    // Enhanced lip sync with phoneme analysis
    final phoneme = _analyzePhoneme(word);
    _animationController.playGesture(phoneme);
  }

  void _handleTTSError() {
    // Fallback to text display or alternative communication
    setState(CharacterState.concerned);
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

  void _triggerEmotionalResponse(EmotionalTone tone) {
    // Map emotional tone to animation states
    switch (tone) {
      case EmotionalTone.happy:
        _animationController.playGesture('smile');
        break;
      case EmotionalTone.concerned:
        _animationController.playGesture('concern');
        break;
      case EmotionalTone.encouraging:
        _animationController.playGesture('thumbs_up');
        break;
      default:
        // No specific gesture
        break;
    }
  }

  void _adaptToCulture(String languageCode) {
    // Adapt character behavior based on cultural context
    switch (languageCode) {
      case 'zh':
        // More formal, respectful approach
        _currentTone = EmotionalTone.professional;
        break;
      case 'es':
        // Warm, family-oriented approach
        _currentTone = EmotionalTone.friendly;
        break;
      case 'fr':
        // Polite, sophisticated approach
        _currentTone = EmotionalTone.professional;
        break;
      default:
        // Default friendly approach
        _currentTone = EmotionalTone.friendly;
    }
  }

  SymptomAnalysis _analyzeSymptom(String symptom, String? context, int? severity) {
    final lowerSymptom = symptom.toLowerCase();
    
    // High priority symptoms
    if (lowerSymptom.contains('fever') && (severity ?? 0) > 102) {
      return SymptomAnalysis(CharacterState.concerned, EmotionalTone.concerned);
    }
    
    if (lowerSymptom.contains('pain') || lowerSymptom.contains('hurt')) {
      return SymptomAnalysis(CharacterState.concerned, EmotionalTone.concerned);
    }
    
    // Positive symptoms
    if (lowerSymptom.contains('better') || lowerSymptom.contains('good')) {
      return SymptomAnalysis(CharacterState.happy, EmotionalTone.encouraging);
    }
    
    // General symptoms
    return SymptomAnalysis(CharacterState.explaining, EmotionalTone.professional);
  }

  String _analyzePhoneme(String word) {
    // Simple phoneme analysis for lip sync
    if (word.contains('a') || word.contains('o')) {
      return 'open_mouth';
    } else if (word.contains('e') || word.contains('i')) {
      return 'smile_mouth';
    } else if (word.contains('u')) {
      return 'round_mouth';
    }
    return 'neutral_mouth';
  }

  void _handleListeningTimeout() {
    setState(CharacterState.concerned);
    _logConversation('Listening timeout', 'listening_timeout');
  }

  void _handleThinkingComplete() {
    setState(CharacterState.idle);
  }

  String _getLocalizedGreeting(String baseGreeting) {
    switch (_currentLanguage) {
      case 'es':
        return '$baseGreeting! Soy el Dr. BeforeDoctor. ¿Cómo puedo ayudarte hoy?';
      case 'zh':
        return '$baseGreeting！我是BeforeDoctor医生。今天我能为您做些什么？';
      case 'fr':
        return '$baseGreeting ! Je suis le Dr. BeforeDoctor. Comment puis-je vous aider aujourd\'hui ?';
      case 'hi':
        return '$baseGreeting! मैं डॉ. BeforeDoctor हूं। आज मैं आपकी कैसे मदद कर सकता हूं?';
      default:
        return '$baseGreeting! I\'m Dr. BeforeDoctor. How can I help you today?';
    }
  }

  String _getLocalizedSymptomPrompt(String type, {String? symptom}) {
    switch (_currentLanguage) {
      case 'es':
        return type == 'follow_up' ? 
            '¿Cómo está el $symptom ahora?' : 
            'Por favor, cuéntame sobre los síntomas.';
      case 'zh':
        return type == 'follow_up' ? 
            '$symptom现在怎么样了？' : 
            '请告诉我症状。';
      case 'fr':
        return type == 'follow_up' ? 
            'Comment va le $symptom maintenant ?' : 
            'S\'il vous plaît, parlez-moi des symptômes.';
      case 'hi':
        return type == 'follow_up' ? 
            '$symptom अब कैसा है?' : 
            'कृपया मुझे लक्षणों के बारे में बताएं।';
      default:
        return type == 'follow_up' ? 
            'How is the $symptom now?' : 
            'Please tell me about the symptoms.';
    }
  }

  void _logStateChange(CharacterState state, EmotionalTone? tone) {
    _conversationHistory.add('State changed to: ${state.name}${tone != null ? ' with tone: ${tone.name}' : ''}');
  }

  void _logSymptomReaction(String symptom, SymptomAnalysis analysis) {
    _conversationHistory.add('Reacted to symptom: $symptom -> ${analysis.state.name} (${analysis.tone.name})');
  }

  void _logConversation(String content, String type) {
    _conversationHistory.add('[$type] $content');
  }

  Map<String, dynamic> _analyzeEmotionalTendencies() {
    // Analyze emotional patterns over time
    return {
      'most_common_tone': _currentTone.name,
      'state_transitions': _conversationHistory.where((log) => log.contains('State changed')).length,
    };
  }

  Map<String, dynamic> _analyzeConversationPatterns() {
    return {
      'total_logs': _conversationHistory.length,
      'symptom_discussions': _symptomFrequency.length,
      'language_preference': _currentLanguage,
    };
  }

  // Getters
  String get currentLanguage => _currentLanguage;
  CharacterState get currentState => _currentState;
  EmotionalTone get currentTone => _currentTone;
  CharacterAnimationController get animationController => _animationController;

  /// Dispose resources
  void dispose() {
    _tts.stop();
    _animationController.dispose();
    print('🎭 Enhanced Character Interaction Engine disposed');
  }
}

/// Data class for symptom analysis results
class SymptomAnalysis {
  final CharacterState state;
  final EmotionalTone tone;
  
  SymptomAnalysis(this.state, this.tone);
}

/// Character states enum
enum CharacterState {
  idle,
  listening,
  speaking,
  thinking,
  concerned,
  happy,
  explaining,
}

/// Emotional tones enum
enum EmotionalTone {
  neutral,
  friendly,
  concerned,
  encouraging,
  professional,
  playful,
}
