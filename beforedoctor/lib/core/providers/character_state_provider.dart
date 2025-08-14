import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../services/character_interaction_engine.dart';
import '../services/rive_animation_manager.dart';
import '../services/lip_sync_service.dart';

final characterEngineProvider = Provider<CharacterInteractionEngine>((ref) {
  return CharacterInteractionEngine.instance;
});

final riveAnimationManagerProvider = Provider<RiveAnimationManager>((ref) {
  return RiveAnimationManager.instance;
});

final lipSyncServiceProvider = Provider<LipSyncService>((ref) {
  return LipSyncService.instance;
});

class CharacterStateNotifier extends StateNotifier<CharacterState> {
  final CharacterInteractionEngine _characterEngine;
  final RiveAnimationManager _animationManager;
  final LipSyncService _lipSyncService;
  final Logger _logger = Logger();

  // Throttle viseme updates to avoid jank
  DateTime? _lastVisemeAt;

  CharacterStateNotifier(
    this._characterEngine,
    this._animationManager,
    this._lipSyncService,
  ) : super(CharacterState.initial());

  Future<void> initialize() async {
    _logger.i('🎭 Initializing Character State Notifier');
    final errors = <String>[];

    try {
      await _characterEngine.initialize();
    } catch (e) {
      errors.add('Character engine: $e');
      _logger.e('❌ Character engine init failed: $e');
    }

    try {
      await _animationManager.initialize();
      // Ensure idle is loaded and set it as the initial artboard
      await _animationManager.ensureLoaded('idle');
      final idle = _animationManager.getArtboard('idle');
      if (idle != null) {
        state = state.copyWith(riveArtboard: idle, currentCharacterState: 'idle');
      }
    } catch (e) {
      errors.add('Animation manager: $e');
      _logger.e('❌ Animation manager init failed: $e');
    }

    try {
      await _lipSyncService.initialize();
    } catch (e) {
      errors.add('Lip-sync service: $e');
      _logger.e('❌ Lip-sync service init failed: $e');
    }

    // Wire callbacks (best-effort)
    try {
      _characterEngine.setOnStateChange(_onCharacterStateChange);
      _characterEngine.setOnEmotionalToneChange(_onEmotionalToneChange);
      _lipSyncService.setPhonemeCallback(_onPhonemeChange);

      CharacterInteractionEngine.setLipSyncService(_lipSyncService);
      _characterEngine.setAnimationManager(_animationManager);
    } catch (e) {
      _logger.w('⚠️ Callback wiring issue: $e');
    }

    if (errors.isEmpty) {
      state = state.copyWith(isInitialized: true, status: CharacterStatus.ready);
      _logger.i('🎭 Character State Notifier initialized');
    } else {
      state = state.copyWith(
        isInitialized: false,
        status: CharacterStatus.error,
        errorMessage: errors.join(' | '),
      );
    }
  }

  Future<void> changeState(String newState) async {
    if (!state.isInitialized) {
      _logger.w('⚠️ Character not initialized, cannot change state');
      return;
    }
    try {
      _logger.d('🎭 Changing state ${state.currentState} → $newState');
      state = state.copyWith(
        currentState: newState,
        lastStateChange: DateTime.now(),
        status: CharacterStatus.transitioning,
      );

      await _characterEngine.changeState(newState);
      await _animationManager.ensureLoaded(newState);
      final artboard = _animationManager.getArtboard(newState);

      state = state.copyWith(
        riveArtboard: artboard ?? state.riveArtboard,
        currentCharacterState: newState,
        status: CharacterStatus.ready,
      );
    } catch (e) {
      _logger.e('❌ Error changing state: $e');
      state = state.copyWith(status: CharacterStatus.error, errorMessage: 'Failed to change state: $e');
    }
  }

  Future<void> changeEmotionalTone(String newTone) async {
    if (!state.isInitialized) return;
    try {
      _logger.d('🎭 Changing emotional tone → $newTone');
      await _characterEngine.changeEmotionalTone(newTone);
      state = state.copyWith(currentEmotionalTone: newTone, lastToneChange: DateTime.now());
    } catch (e) {
      _logger.e('❌ Error changing emotional tone: $e');
    }
  }

  Future<void> startSpeaking(String text) async {
    if (!state.isInitialized) return;
    try {
      _logger.d('🎭 Start speaking: $text');
      state = state.copyWith(isSpeaking: true, currentMessage: text, status: CharacterStatus.speaking);
      await changeState('speaking');
      await _lipSyncService.speakWithLipSync(text);

      final history = List<String>.from(state.conversationHistory)..add(text);
      state = state.copyWith(conversationHistory: history, lastMessageTime: DateTime.now());
    } catch (e) {
      _logger.e('❌ Error starting speech: $e');
      state = state.copyWith(isSpeaking: false, status: CharacterStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> stopSpeaking() async {
    if (!state.isInitialized) return;
    try {
      _logger.d('🎭 Stop speaking');
      await _lipSyncService.stopSpeaking();
      state = state.copyWith(isSpeaking: false, currentMessage: '', status: CharacterStatus.ready);
      await changeState('idle');
    } catch (e) {
      _logger.e('❌ Error stopping speech: $e');
    }
  }

  Future<void> startListening() async {
    if (!state.isInitialized) return;
    try {
      _logger.d('🎭 Start listening');
      state = state.copyWith(isListening: true, status: CharacterStatus.listening);
      await changeState('listening');
    } catch (e) {
      _logger.e('❌ Error starting listening: $e');
    }
  }

  Future<void> stopListening() async {
    if (!state.isInitialized) return;
    try {
      _logger.d('🎭 Stop listening');
      state = state.copyWith(isListening: false, status: CharacterStatus.ready);
      await changeState('idle');
    } catch (e) {
      _logger.e('❌ Error stopping listening: $e');
    }
  }

  void addMessage(String message) {
    final history = List<String>.from(state.conversationHistory)..add(message);
    state = state.copyWith(conversationHistory: history, lastMessageTime: DateTime.now());
  }

  void clearConversationHistory() {
    state = state.copyWith(conversationHistory: [], lastMessageTime: null);
  }

  Future<void> startConversation() async {
    if (!state.isInitialized) return;
    try {
      _logger.d('🎭 Conversation flow');
      await startListening();
      await Future.delayed(const Duration(seconds: 2));
      await changeState('thinking');
      await Future.delayed(const Duration(seconds: 1));
      await changeState('speaking');

      const message = "Hello! I'm Dr. Care. How can I help you today?";
      state = state.copyWith(isSpeaking: true, currentMessage: message, status: CharacterStatus.speaking);
      addMessage(message);
      await _lipSyncService.speakWithLipSync(message);

      await Future.delayed(const Duration(milliseconds: 400));
      await changeState('idle');
      state = state.copyWith(isListening: false, isSpeaking: false, currentMessage: '', status: CharacterStatus.ready);
    } catch (e) {
      _logger.e('❌ Conversation error: $e');
    }
  }

  Future<void> showEmotionalResponse(String emotion) async {
    if (!state.isInitialized) return;
    try {
      _logger.d('🎭 Emotional response: $emotion');
      await changeState(emotion);
      await Future.delayed(const Duration(seconds: 2));
      await changeState('idle');
    } catch (e) {
      _logger.e('❌ Emotional response error: $e');
    }
  }

  void _onCharacterStateChange(String newState) {
    _logger.d('🎭 Engine state callback: $newState');
  }

  void _onEmotionalToneChange(String newTone) {
    _logger.d('🎭 Engine tone callback: $newTone');
  }

  void _onPhonemeChange(String phoneme) {
    // Throttle to ~30ms to prevent spamming the state machine
    final now = DateTime.now();
    if (_lastVisemeAt != null && now.difference(_lastVisemeAt!).inMilliseconds < 30) return;
    _lastVisemeAt = now;

    try {
      _animationManager.applyMouthShape(phoneme);
    } catch (e) {
      _logger.w('⚠️ Failed to apply viseme $phoneme: $e');
    }
  }

  @override
  void dispose() {
    _logger.i('🎭 Character State Notifier disposed');
    super.dispose();
  }
}

final characterStateProvider =
    StateNotifierProvider<CharacterStateNotifier, CharacterState>((ref) {
  final engine = ref.watch(characterEngineProvider);
  final anim = ref.watch(riveAnimationManagerProvider);
  final lip = ref.watch(lipSyncServiceProvider);
  return CharacterStateNotifier(engine, anim, lip);
});

class CharacterState {
  final bool isInitialized;
  final String currentState;
  final String currentEmotionalTone;
  final bool isSpeaking;
  final bool isListening;
  final String currentMessage;
  final List<String> conversationHistory;
  final CharacterStatus status;
  final String? errorMessage;
  final DateTime? lastStateChange;
  final DateTime? lastToneChange;
  final DateTime? lastMessageTime;
  final dynamic riveArtboard;
  final String currentCharacterState;

  const CharacterState({
    required this.isInitialized,
    required this.currentState,
    required this.currentEmotionalTone,
    required this.isSpeaking,
    required this.isListening,
    required this.currentMessage,
    required this.conversationHistory,
    required this.status,
    this.errorMessage,
    this.lastStateChange,
    this.lastToneChange,
    this.lastMessageTime,
    this.riveArtboard,
    required this.currentCharacterState,
  });

  factory CharacterState.initial() {
    return const CharacterState(
      isInitialized: false,
      currentState: 'idle',
      currentEmotionalTone: 'neutral',
      isSpeaking: false,
      isListening: false,
      currentMessage: '',
      conversationHistory: [],
      status: CharacterStatus.initializing,
      currentCharacterState: 'idle',
    );
  }

  CharacterState copyWith({
    bool? isInitialized,
    String? currentState,
    String? currentEmotionalTone,
    bool? isSpeaking,
    bool? isListening,
    String? currentMessage,
    List<String>? conversationHistory,
    CharacterStatus? status,
    String? errorMessage,
    DateTime? lastStateChange,
    DateTime? lastToneChange,
    DateTime? lastMessageTime,
    dynamic riveArtboard,
    String? currentCharacterState,
  }) {
    return CharacterState(
      isInitialized: isInitialized ?? this.isInitialized,
      currentState: currentState ?? this.currentState,
      currentEmotionalTone: currentEmotionalTone ?? this.currentEmotionalTone,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      currentMessage: currentMessage ?? this.currentMessage,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastStateChange: lastStateChange ?? this.lastStateChange,
      lastToneChange: lastToneChange ?? this.lastToneChange,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      riveArtboard: riveArtboard ?? this.riveArtboard,
      currentCharacterState: currentCharacterState ?? this.currentCharacterState,
    );
  }
}

enum CharacterStatus {
  initializing,
  ready,
  transitioning,
  speaking,
  listening,
  error,
}
