import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../services/3d_character_service.dart';
import '../../../../services/stt_service.dart';
import '../../../../services/llm_service.dart';
import '../../../../services/tts_service.dart';
import '../../../../services/translation_service.dart';
import '../../../../core/services/character_interaction_engine.dart';
import '../../services/character_animator.dart';
import '../widgets/mouse_3d_widget.dart';
import '../../../../core/theme/pediatric_theme.dart';

/// Enhanced 3D Character Screen with Native Flutter Rendering
class EnhancedDoctorCharacterScreen extends ConsumerStatefulWidget {
  const EnhancedDoctorCharacterScreen({super.key});

  @override
  ConsumerState<EnhancedDoctorCharacterScreen> createState() => _EnhancedDoctorCharacterScreenState();
}

class _EnhancedDoctorCharacterScreenState extends ConsumerState<EnhancedDoctorCharacterScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  
  // Character Animation System
  CharacterAnimator? _characterAnimator;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Service Instances
  final ThreeDCharacterService _characterService = ThreeDCharacterService();
  final STTService _sttService = STTService();
  final LLMService _llmService = LLMService();
  final TTSService _ttsService = TTSService();
  final TranslationService _translationService = TranslationService();
  final CharacterInteractionEngine _characterEngine = CharacterInteractionEngine.instance;
  
  // Voice Interaction States
  bool _isListening = false;
  final bool _isSpeaking = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _aiResponse = '';
  String _detectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Delay heavy operations to prevent frame skipping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCharacterSystem();
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _characterAnimator?.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize all services
      await _characterService.initialize();
      await _sttService.initialize();
      await _llmService.initialize();
      await _ttsService.initTTS();
      await _translationService.preloadCommonLanguages();
      await _characterEngine.initialize();

      setState(() {
        // _isInitialized = true; // Removed as per edit hint
      });

      _logger.i('🎭 All services initialized successfully');
    } catch (e) {
      _logger.e('❌ Error initializing services: $e');
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  void _initializeCharacterSystem() {
    _logger.i('🎭 Initializing Enhanced Character System');
    // Use compute for heavy asset loading
    _testAssetLoading();
  }

  Future<void> _testAssetLoading() async {
    try {
      // Load asset directly in main isolate since rootBundle requires binding
      final bytes = await rootBundle.load('assets/3d/jaguar.glb');
      _logger.i('✅ Jaguar GLB loaded: ${bytes.lengthInBytes} bytes');
    } catch (e) {
      _logger.e('❌ Failed to load jaguar.glb: $e');
    }
  }

  void _driveAnimation() {
    if (_characterAnimator != null) {
      final currentState = _characterService.currentState;
      final animationName = _mapStateToAnimation(currentState);
      _characterAnimator!.play(animationName);
      _logger.i('🎭 Driving animation: $animationName for state: $currentState');
    }
  }

  String _mapStateToAnimation(String state) {
    switch (state.toLowerCase()) {
      case 'idle':
        return 'Idle';
      case 'listening':
        return 'Listen';
      case 'speaking':
        return 'Speak';
      case 'thinking':
        return 'Think';
      case 'concerned':
        return 'Concerned';
      case 'urgent':
        return 'Urgent';
      case 'happy':
        return 'Happy';
      case 'explaining':
        return 'Explain';
      default:
        return 'Idle';
    }
  }

  // Voice Interaction Methods
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });
      
      _logger.i('🎤 Starting voice recognition...');
      await _sttService.startListening(
        onResult: (text, detectedLanguage) {
          setState(() {
            _recognizedText = text;
            _detectedLanguage = detectedLanguage;
          });
        },
        onError: (error) {
          _logger.e('❌ STT Error: $error');
        },
      );
      
      // Update character state
      await _characterService.changeState('listening');
      _driveAnimation();
      
    } catch (e) {
      _logger.e('❌ Error starting voice recognition: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      await _sttService.stopListening();
      
      setState(() {
        _isListening = false;
      });
      
      // Process recognized text
      if (_recognizedText.isNotEmpty) {
        await _processRecognizedText();
      }
      
      // Update character state
      await _characterService.changeState('idle');
      _driveAnimation();
      
    } catch (e) {
      _logger.e('❌ Error stopping voice recognition: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _processRecognizedText() async {
    if (_recognizedText.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      _logger.i('🧠 Processing recognized text: $_recognizedText');
      
      // Get AI response
      final response = await _llmService.getLLMResponse(_recognizedText);
      
      setState(() {
        _aiResponse = response;
        _isProcessing = false;
      });
      
      // Update character state
      await _characterService.changeState('speaking');
      _driveAnimation();
      
      // Speak the response
      await _ttsService.speak(response);
      
      // Update character state back to idle
      await _characterService.changeState('idle');
      _driveAnimation();
      
    } catch (e) {
      _logger.e('❌ Error processing text: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'idle':
        return Colors.green;
      case 'listening':
        return Colors.blue;
      case 'speaking':
        return Colors.orange;
      case 'thinking':
        return Colors.purple;
      case 'concerned':
        return Colors.red;
      case 'urgent':
        return Colors.red;
      case 'happy':
        return Colors.yellow;
      case 'explaining':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PediatricTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                _buildCharacterDisplay(),
                _buildVoiceControls(),
                _buildStatusIndicators(),
                _buildConversationArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: PediatricTheme.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Dr. Healthie',
              style: TextStyle(
                color: PediatricTheme.onBackground,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_off,
              color: _isListening ? Colors.green : PediatricTheme.onBackground,
            ),
            onPressed: _toggleListening,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterDisplay() {
    return Container(
      width: double.infinity,
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Mouse3D(
            onReady: (controller) {
              _characterAnimator = CharacterAnimator(controller);
              _logger.i('🎭 3D Character Animator ready');
              _driveAnimation();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Start Conversation Button (Primary Voice Control)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text('Start Conversation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Character State
          _buildStatusChip(
            'Character',
            _characterService.currentState,
            _getStateColor(_characterService.currentState),
          ),

          // Language
          _buildStatusChip(
            'Language',
            _detectedLanguage.toUpperCase(),
            Colors.orange,
          ),

          // Status
          _buildStatusChip(
            'Status',
            _isListening ? 'Listening' : (_isSpeaking ? 'Speaking' : 'Ready'),
            _isListening ? Colors.green : (_isSpeaking ? Colors.blue : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PediatricTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conversation Header
          Row(
            children: [
              Icon(Icons.chat_bubble, color: PediatricTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Conversation',
                style: TextStyle(
                  color: PediatricTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Conversation Content
          Expanded(
            child: _isProcessing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Processing...', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  )
                : _recognizedText.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You said:',
                            style: TextStyle(
                              color: PediatricTheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _recognizedText,
                            style: TextStyle(
                              color: PediatricTheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          if (_aiResponse.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Response:',
                              style: TextStyle(
                                color: PediatricTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _aiResponse,
                              style: TextStyle(
                                color: PediatricTheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_none, color: Colors.grey[400], size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Start Conversation" to begin',
                              style: TextStyle(
                                color: PediatricTheme.primary,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
