import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/services/symptom_extraction_service.dart';
import '../../../../core/services/ai_response_orchestrator.dart';
import '../../../../core/services/ai_prompt_service.dart';
import '../../../../core/services/treatment_recommendation_service.dart';
import '../../../../core/services/cdc_risk_assessment_service.dart';
import '../../../../core/services/multi_symptom_analyzer.dart';
import '../../../../core/services/logging_service.dart';
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
  late VoiceInputService _voiceService;
  late SymptomExtractionService _symptomExtractionService;
  late AIResponseOrchestrator _aiResponseOrchestrator;
  late AIPromptService _aiPromptService;
  late TreatmentRecommendationService _treatmentRecommendationService;
  late CDCRiskAssessmentService _cdcRiskAssessmentService;
  late MultiSymptomAnalyzer _multiSymptomAnalyzer;
  late LoggingService _loggingService;
  
  // Conversation state
  String _lastTranscription = '';
  String _lastResponse = '';
  List<ConversationMessage> _conversationMessages = [];
  
  // Page controller for TikTok-style navigation
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    
    // Initialize ML/AI services (using real services now)
    _initializeServices();
    
    // Add initial welcome message
    _addMessage("Hello! I'm Dr. Healthie. How can I help you today?", false);
  }
  
  /// Add a new message to the conversation
  void _addMessage(String text, bool isUser) {
    setState(() {
      _conversationMessages.add(ConversationMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
  }
  
  void _initializeServices() async {
    try {
      // Initialize real AI/ML services
      _voiceService = VoiceInputService.instance;
      _symptomExtractionService = SymptomExtractionService();
      _aiResponseOrchestrator = AIResponseOrchestrator();
      _aiPromptService = AIPromptService();
      _treatmentRecommendationService = TreatmentRecommendationService();
      _cdcRiskAssessmentService = CDCRiskAssessmentService();
      _multiSymptomAnalyzer = MultiSymptomAnalyzer();
      _loggingService = LoggingService();
      
      // Initialize services that need async setup
      await _aiPromptService.loadTemplates();
      await _voiceService.initialize();
      
      // Set up voice recognition streams
      _setupVoiceStreams();
      
      print('✅ All AI/ML services initialized successfully');
    } catch (e) {
      print('❌ Error initializing services: $e');
      // Fallback to basic functionality
    }
  }
  
  void _setupVoiceStreams() {
    // Listen for voice recognition results
    _voiceService.transcriptionStream.listen((transcription) {
      if (transcription.isNotEmpty) {
        _lastTranscription = transcription;
        _processVoiceInput(transcription);
      }
    });
    
    // Listen for confidence updates
    _voiceService.confidenceStream.listen((confidence) {
      // Update UI with confidence level
      print('🎯 Voice confidence: ${(confidence * 100).toStringAsFixed(1)}%');
    });
    
    // Listen for listening state changes
    _voiceService.listeningStream.listen((isListening) {
      if (isListening) {
        _changeStatus(AppStatus.listening);
      } else if (_currentStatus == AppStatus.listening) {
        _changeStatus(AppStatus.processing);
      }
    });
    
    // Listen for processing state changes
    _voiceService.processingStream.listen((isProcessing) {
      if (isProcessing) {
        _changeStatus(AppStatus.processing);
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    
    // Dispose ML/AI services
    if (_voiceService is VoiceInputService) {
      // VoiceInputService is a singleton, no need to dispose
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
      
      // For now, we'll use the simulateVoiceInput method since real speech recognition isn't implemented yet
      // In the future, this will be real voice recognition
      await _voiceService.simulateVoiceInput("I want to talk about pain in my back");
      
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
      _changeStatus(AppStatus.processing);
      
      // The voice service will automatically process and send results via streams
      // No need to manually call stop here
    } catch (e) {
      print('Error stopping voice recognition: $e');
      _changeStatus(AppStatus.ready);
    }
  }
  
  /// Process voice input through comprehensive AI pipeline
  Future<void> _processVoiceInput(String text) async {
    try {
      _changeStatus(AppStatus.processing);
      
      // Add user message to conversation
      _addMessage(text, true);
      
      // Step 1: Extract symptoms using AI (now AI-first approach)
      final extractionResult = await _symptomExtractionService.extractSymptoms(text);
      
      if (extractionResult.isSuccessful) {
        print('🎯 Extracted symptoms: ${extractionResult.symptoms}');
        
        // Step 2: Get comprehensive AI response using orchestrator
        final aiResponse = await _aiResponseOrchestrator.getComprehensiveResponse(
          symptoms: extractionResult.symptoms,
          childContext: _getChildContext(),
          userQuestion: text,
        );
        
        // Step 3: Update conversation with AI response
        _lastResponse = aiResponse['response'] ?? 'I understand your concern. Let me provide some guidance.';
        _addMessage(_lastResponse, false);
        
        // Step 4: Check if medical attention is required
        if (aiResponse['risk_level'] == 'high' || aiResponse['requires_medical_attention'] == true) {
          _changeStatus(AppStatus.concerned);
          // Could show alert dialog here
        } else {
          _changeStatus(AppStatus.complete);
        }
        
        // Step 5: Log the interaction
        await _loggingService.logInteraction(
          interactionType: 'symptom_extraction',
          symptomCategory: extractionResult.symptoms.isNotEmpty ? extractionResult.symptoms.first : 'unknown',
          modelUsed: 'ai_orchestrator',
          responseTime: 0, // We'll calculate this in the future
          success: true,
          metadata: {
            'extracted_symptoms': extractionResult.symptoms,
            'confidence': extractionResult.confidence,
            'ai_response': aiResponse,
            'child_context': _getChildContext(),
          },
        );
        
        print('✅ AI processing completed successfully');
      } else {
        // Fallback to basic processing
        _lastResponse = "I heard you say: '$text'. Could you please provide more details about the symptoms?";
        _addMessage(_lastResponse, false);
        _changeStatus(AppStatus.complete);
      }
      
      // Reset to ready state after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_currentStatus == AppStatus.complete || _currentStatus == AppStatus.concerned) {
          _changeStatus(AppStatus.ready);
        }
      });
      
    } catch (e) {
      print('Error processing voice input: $e');
      _lastResponse = "I'm having trouble processing that right now. Please try again.";
      _addMessage(_lastResponse, false);
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

  /// Get child context for AI processing (placeholder for now)
  Map<String, dynamic> _getChildContext() {
    return {
      'child_age': 5, // Default age - will come from child profile
      'child_gender': 'unknown',
      'child_weight': 20.0, // kg - will come from child profile
      'allergies': [], // Will come from child profile
      'current_medications': [], // Will come from child profile
      'medical_history': [], // Will come from child profile
    };
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
    return ConversationArea(
      messages: _conversationMessages,
      audience: _audience,
    );
  }
}
