import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/services/nlu_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/services/mock_voice_service.dart';
import '../../../../core/services/mock_nlu_service.dart';
import '../../../../core/services/mock_tts_service.dart';
import '../../../../core/models/app_models.dart';
import '../../domain/models/conversation_message.dart';
import '../widgets/particle_background.dart';
import '../widgets/status_header.dart';
import '../widgets/voice_interaction_area.dart';
import '../widgets/conversation_area.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/page_content.dart';

/// Enhanced Color Based Page - Pediatric Clinic Theme
/// Features soft colors, accessibility, and professional healthcare UX
/// 
/// TONE ADAPTATION SYSTEM:
/// - Automatically adapts language based on user audience (kid vs parent)
/// - Kid mode: Warm, friendly language ("Thinking...", "Let me tell you")
/// - Parent mode: Professional, clinical language ("Processing...", "Speaking...")
/// - Can be toggled for testing and will be driven by user profile in production
class ColorBasedPage extends ConsumerStatefulWidget {
  const ColorBasedPage({super.key});

  @override
  ConsumerState<ColorBasedPage> createState() => _ColorBasedPageState();
}

class _ColorBasedPageState extends ConsumerState<ColorBasedPage> {
  // UI state
  AppStatus _currentStatus = AppStatus.ready;
  int _currentPageIndex = 0; // 0: Chat, 1: Insights, 2: Log, 3: Settings
  
  // Audience for tone adaptation (kid vs parent)
  Audience _audience = Audience.child; // Default to kid-friendly language
  
  // ML/AI Services
  late VoiceService _voiceService;
  late NLUService _nluService;
  late TTSService _ttsService;
  
  // Conversation state
  String _lastTranscription = '';
  String _lastResponse = '';
  
  // Page controller for TikTok-style navigation
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    
    // Initialize ML/AI services (using mocks for now)
    _initializeServices();
  }
  
  void _initializeServices() {
    _voiceService = MockVoiceService();
    _nluService = MockNLUService();
    _ttsService = MockTTSService();
    
    // Set up voice recognition streams
    _setupVoiceStreams();
    
    // Set up TTS event streams
    _setupTTSStreams();
  }
  
  void _setupVoiceStreams() {
    // Listen for voice recognition results
    _voiceService.results.listen((result) {
      if (result.isFinal) {
        _lastTranscription = result.text;
        _processVoiceInput(result.text);
      }
    });
    
    // Listen for VAD silence (user stopped speaking)
    _voiceService.vadSilence.listen((isSilent) {
      if (isSilent && _currentStatus == AppStatus.listening) {
        _onVadSilence();
      }
    });
  }
  
  void _setupTTSStreams() {
    // Listen for TTS events
    _ttsService.events.listen((event) {
      switch (event.type) {
        case TTSEventType.started:
          _changeStatus(AppStatus.speaking);
          break;
        case TTSEventType.completed:
          _changeStatus(AppStatus.ready);
          break;
        case TTSEventType.error:
          _changeStatus(AppStatus.ready);
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    
    // Dispose ML/AI services
    if (_voiceService is MockVoiceService) {
      (_voiceService as MockVoiceService).dispose();
    }
    if (_ttsService is MockTTSService) {
      (_ttsService as MockTTSService).dispose();
    }
    
    super.dispose();
  }

  void _changeStatus(AppStatus newStatus) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentStatus = newStatus;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  /// Switch between kid and parent modes
  void _switchAudience() {
    setState(() {
      _audience = _audience == Audience.child 
          ? Audience.parent 
          : Audience.child;
    });
  }
  
  // ========================================
  // ML/AI INTEGRATION METHODS
  // ========================================
  
  /// Start voice recognition when mic is tapped
  Future<void> _startVoiceRecognition() async {
    try {
      HapticFeedback.lightImpact();
      await _voiceService.startListening();
      _changeStatus(AppStatus.listening);
    } catch (e) {
      print('Error starting voice recognition: $e');
      _changeStatus(AppStatus.ready);
    }
  }
  
  /// Stop voice recognition and process input
  Future<void> _stopVoiceRecognition() async {
    try {
      HapticFeedback.selectionClick();
      final result = await _voiceService.stopAndTranscribe();
      _changeStatus(AppStatus.processing);
      
      // Process the voice input
      await _processVoiceInput(result.text);
    } catch (e) {
      print('Error stopping voice recognition: $e');
      _changeStatus(AppStatus.ready);
    }
  }
  
  /// Process voice input through NLU
  Future<void> _processVoiceInput(String text) async {
    try {
      _changeStatus(AppStatus.processing);
      
      // Process through NLU
      final nluResult = await _nluService.processText(text);
      _lastResponse = nluResult.response;
      
      // Check if medical attention is required
      if (nluResult.requiresMedicalAttention) {
        _changeStatus(AppStatus.concerned);
        // Could show alert dialog here
      }
      
      // Speak the response
      _changeStatus(AppStatus.speaking);
      await _ttsService.speak(nluResult.response);
      
      // Status will be set to 'ready' by TTS completion event
    } catch (e) {
      print('Error processing voice input: $e');
      _changeStatus(AppStatus.ready);
    }
  }
  
  /// Handle VAD silence (user stopped speaking)
  void _onVadSilence() {
    if (_currentStatus == AppStatus.listening) {
      _stopVoiceRecognition();
    }
  }
  
  /// Raise concern flag (e.g., high fever detected)
  void _raiseConcern() {
    _changeStatus(AppStatus.concerned);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background with particles and scrim
          _buildAnimatedBackground(reduceMotion),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with status
                StatusHeader(
                  currentStatus: _currentStatus,
                  audience: _audience,
                  onStatusChange: _changeStatus,
                ),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildChatPage(),
                      const InsightsPage(),
                      const LogPage(),
                      const SettingsPage(),
                    ],
                  ),
                ),
                
                // TikTok-style bottom navigation
                BottomNavigation(
                  currentPageIndex: _currentPageIndex,
                  currentStatus: _currentStatus,
                  onTabTapped: _onTabTapped,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool reduceMotion) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentStatus),
        decoration: BoxDecoration(
          gradient: statusGradient(_currentStatus),
        ),
        child: Stack(
          children: [
            // Particle background (respects reduce motion)
            ParticleBackground(
              currentStatus: _currentStatus,
              reduceMotion: reduceMotion,
            ),
            
            // Scrim overlay for contrast compliance
            IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Main voice interaction area
          Expanded(
            child: Center(
              child: VoiceInteractionArea(
                currentStatus: _currentStatus,
                audience: _audience,
                onStartListening: _startVoiceRecognition,
                onStopListening: _stopVoiceRecognition,
                onStatusChange: _changeStatus, // Add this callback
              ),
            ),
          ),
          
          // Conversation area
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ClinicColors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ClinicColors.white.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildConversationArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    // Show real conversation data if available
    final messages = <ConversationMessage>[];
    
    if (_lastTranscription.isNotEmpty) {
      messages.add(ConversationMessage(
        text: _lastTranscription,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    }
    
    if (_lastResponse.isNotEmpty) {
      messages.add(ConversationMessage(
        text: _lastResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
    
    // Add placeholder messages if no real data
    if (messages.isEmpty) {
      messages.addAll([
        ConversationMessage(
          text: "Ouch, my tummy hurts",
          isUser: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        ConversationMessage(
          text: _audience == Audience.child ? "Where does it hurt?" : "Where does it hurt exactly?",
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ]);
    }
    
    return ConversationArea(
      messages: messages,
      audience: _audience,
    );
  }
}
