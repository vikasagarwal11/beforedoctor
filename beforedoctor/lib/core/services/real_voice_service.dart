import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'logging_service.dart';

/// Real Voice Service with actual microphone input and voice activity detection
/// Implements basic voice state management with simulated transcription for now
class RealVoiceService {
  static RealVoiceService? _instance;
  static RealVoiceService get instance => _instance ??= RealVoiceService._internal();

  RealVoiceService._internal();

  // Services
  final LoggingService _loggingService = LoggingService();
  
  // Audio session
  AudioSession? _audioSession;
  AudioPlayer? _audioPlayer;
  
  // Voice state
  VoiceState _currentState = VoiceState.idle;
  bool _isListening = false;
  bool _isProcessing = false;
  
  // Voice activity detection
  Timer? _vadTimer;
  DateTime? _lastVoiceActivity;
  static const Duration _vadTimeout = Duration(seconds: 2);
  
  // Stream controllers
  final StreamController<VoiceState> _stateController = StreamController<VoiceState>.broadcast();
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  final StreamController<double> _confidenceController = StreamController<double>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  final StreamController<VoiceActivityEvent> _vadController = StreamController<VoiceActivityEvent>.broadcast();
  
  // Streams
  Stream<VoiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<double> get confidenceStream => _confidenceController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<VoiceActivityEvent> get vadStream => _vadController.stream;
  
  // Getters
  VoiceState get currentState => _currentState;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;

  /// Initialize the real voice service
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Configure audio session
      await _configureAudioSession();
      
      // Initialize audio player for feedback
      _audioPlayer = AudioPlayer();
      
      print('✅ Real voice service initialized successfully');
      return true;
      
    } catch (e) {
      print('❌ Error initializing real voice service: $e');
      return false;
    }
  }

  /// Configure audio session for voice recognition
  Future<void> _configureAudioSession() async {
    _audioSession = await AudioSession.instance;
    
          await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (_isListening || _isProcessing) return;
    
    try {
      _isListening = true;
      _listeningController.add(true);
      
      // Change state to listening
      _changeState(VoiceState.listening);
      
      // Start voice activity detection
      _startVoiceActivityDetection();
      
      // Play start sound (optional)
      await _playStartSound();
      
      print('🎤 Started listening for voice input');
      
    } catch (e) {
      print('❌ Error starting voice listening: $e');
      _isListening = false;
      _listeningController.add(false);
      _changeState(VoiceState.idle);
    }
  }

  /// Stop listening and process transcription
  Future<VoiceResult> stopAndTranscribe() async {
    if (!_isListening) {
      return VoiceResult.empty();
    }
    
    try {
      _isListening = false;
      _listeningController.add(false);
      
      // Stop VAD
      _stopVoiceActivityDetection();
      
      // Change state to thinking
      _changeState(VoiceState.thinking);
      
      // Simulate transcription processing (replace with actual STT later)
      final result = await _processTranscription();
      
      // Change state based on result
      if (result.isValid) {
        _changeState(VoiceState.speaking);
      } else {
        _changeState(VoiceState.idle);
      }
      
      print('🛑 Stopped listening and processed transcription');
      return result;
      
    } catch (e) {
      print('❌ Error stopping voice listening: $e');
      _changeState(VoiceState.idle);
      return VoiceResult.error(e.toString());
    }
  }

  /// Process transcription (simulated for now)
  Future<VoiceResult> _processTranscription() async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate transcription result
    final transcription = "My child has a fever of 102 degrees";
    final confidence = 0.95;
    
    // Emit transcription
    _transcriptionController.add(transcription);
    _confidenceController.add(confidence);
    
    return VoiceResult(
      text: transcription,
      confidence: confidence,
      isFinal: true,
      language: 'en',
      duration: const Duration(seconds: 3),
    );
  }

  /// Start voice activity detection
  void _startVoiceActivityDetection() {
    _vadTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Simulate voice activity detection
      // In real implementation, this would analyze audio input
      _detectVoiceActivity();
    });
  }

  /// Stop voice activity detection
  void _stopVoiceActivityDetection() {
    _vadTimer?.cancel();
    _vadTimer = null;
  }

  /// Detect voice activity (simulated for now)
  void _detectVoiceActivity() {
    // Simulate random voice activity
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    if (random < 30) { // 30% chance of voice activity
      _onVoiceDetected();
    }
  }

  /// Handle voice activity detected
  void _onVoiceDetected() {
    _lastVoiceActivity = DateTime.now();
    
    // Emit VAD event
    _vadController.add(VoiceActivityEvent(
      timestamp: _lastVoiceActivity!,
      isActive: true,
      confidence: 0.8,
    ));
    
    // Update state to active listening
    if (_currentState == VoiceState.listening) {
      _changeState(VoiceState.activeListening);
    }
  }

  /// Change voice state
  void _changeState(VoiceState newState) {
    if (_currentState == newState) return;
    
    _currentState = newState;
    _stateController.add(newState);
    
    print('🔄 Voice state changed: ${_currentState.name}');
    
    // Handle state-specific actions
    _handleStateChange(newState);
  }

  /// Handle state-specific actions
  void _handleStateChange(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        // Start listening animation
        break;
      case VoiceState.activeListening:
        // Voice detected, show active feedback
        break;
      case VoiceState.thinking:
        // Show thinking animation
        break;
      case VoiceState.speaking:
        // Start speaking animation
        break;
      case VoiceState.serious:
        // Show serious/urgent state
        break;
      case VoiceState.idle:
        // Return to idle state
        break;
    }
  }

  /// Play start sound
  Future<void> _playStartSound() async {
    try {
      // Play a gentle "ding" sound to indicate listening started
      // You can add an audio file to assets and play it here
      print('🔊 Playing start sound');
    } catch (e) {
      print('❌ Error playing start sound: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;
    
    _isListening = false;
    _listeningController.add(false);
    _stopVoiceActivityDetection();
    _changeState(VoiceState.idle);
    
    print('❌ Cancelled voice listening');
  }

  /// Get current voice state
  VoiceState getCurrentState() => _currentState;

  /// Check if voice is active
  bool get isVoiceActive => _lastVoiceActivity != null && 
      DateTime.now().difference(_lastVoiceActivity!) < _vadTimeout;

  /// Dispose resources
  void dispose() {
    _vadTimer?.cancel();
    _audioPlayer?.dispose();
    _stateController.close();
    _transcriptionController.close();
    _confidenceController.close();
    _listeningController.close();
    _vadController.close();
  }
}

/// Voice states for UI color changes
enum VoiceState {
  idle,           // Default state - Neutral color
  listening,      // Listening for voice - Blue
  activeListening, // Voice detected - Bright blue
  thinking,       // Processing - Orange
  speaking,       // Speaking response - Green
  serious,        // Serious/urgent - Red
}

/// Voice activity detection event
class VoiceActivityEvent {
  final DateTime timestamp;
  final bool isActive;
  final double confidence;

  VoiceActivityEvent({
    required this.timestamp,
    required this.isActive,
    required this.confidence,
  });
}

/// Result from voice recognition
class VoiceResult {
  final String text;
  final double confidence;
  final bool isFinal;
  final String? language;
  final Duration duration;

  const VoiceResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
    this.language,
    required this.duration,
  });

  /// Empty result
  factory VoiceResult.empty() => const VoiceResult(
    text: '',
    confidence: 0.0,
    isFinal: false,
    duration: Duration.zero,
  );

  /// Error result
  factory VoiceResult.error(String error) => VoiceResult(
    text: 'Error: $error',
    confidence: 0.0,
    isFinal: true,
    duration: Duration.zero,
  );

  /// Check if result is valid
  bool get isValid => text.isNotEmpty && confidence > 0.0;

  /// Check if result is empty
  bool get isEmpty => text.isEmpty;

  /// Check if result is an error
  bool get isError => text.startsWith('Error:');
}
