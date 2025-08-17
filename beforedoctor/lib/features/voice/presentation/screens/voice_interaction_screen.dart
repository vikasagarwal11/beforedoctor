import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/real_voice_service.dart';
import '../../../../core/services/hybrid_ai_service.dart';
import '../../../../core/services/firebase_sync_service.dart';
import '../../../../core/database/database_helper.dart';
import '../widgets/voice_state_aware_ui.dart';

/// Voice Interaction Screen
/// Complete voice interaction with color-changing UI and real-time feedback
class VoiceInteractionScreen extends ConsumerStatefulWidget {
  const VoiceInteractionScreen({super.key});

  @override
  ConsumerState<VoiceInteractionScreen> createState() => _VoiceInteractionScreenState();
}

class _VoiceInteractionScreenState extends ConsumerState<VoiceInteractionScreen>
    with TickerProviderStateMixin {
  // Services
  late RealVoiceService _voiceService;
  late HybridAIService _aiService;
  late FirebaseSyncService _syncService;
  late DatabaseHelper _dbHelper;
  
  // State
  VoiceState _currentVoiceState = VoiceState.idle;
  String _transcription = '';
  String _aiResponse = '';
  double _confidence = 0.0;
  bool _isProcessing = false;
  bool _isSyncing = false;
  
  // Animation controllers
  late AnimationController _micController;
  late AnimationController _responseController;
  
  // Animations
  late Animation<double> _micScaleAnimation;
  late Animation<double> _responseOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _voiceService = RealVoiceService.instance;
    _aiService = HybridAIService.instance;
    _syncService = FirebaseSyncService.instance;
    _dbHelper = DatabaseHelper.instance;
    
    // Initialize animations
    _initializeAnimations();
    
    // Listen to voice state changes
    _listenToVoiceState();
    
    // Initialize services
    _initializeServices();
  }

  void _initializeAnimations() {
    // Microphone button animation
    _micController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _micScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _micController,
      curve: Curves.easeInOut,
    ));
    
    // Response animation
    _responseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _responseOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _responseController,
      curve: Curves.easeInOut,
    ));
  }

  void _listenToVoiceState() {
    _voiceService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentVoiceState = state;
        });
        
        // Handle state-specific actions
        _handleVoiceStateChange(state);
      }
    });
    
    _voiceService.transcriptionStream.listen((text) {
      if (mounted) {
        setState(() {
          _transcription = text;
        });
      }
    });
    
    _voiceService.confidenceStream.listen((conf) {
      if (mounted) {
        setState(() {
          _confidence = conf;
        });
      }
    });
  }

  void _handleVoiceStateChange(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        _startListeningFeedback();
        break;
      case VoiceState.activeListening:
        _onVoiceDetected();
        break;
      case VoiceState.thinking:
        _startThinkingFeedback();
        break;
      case VoiceState.speaking:
        _startSpeakingFeedback();
        break;
      case VoiceState.serious:
        _showSeriousWarning();
        break;
      case VoiceState.idle:
        _resetToIdle();
        break;
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize voice service
      final voiceInitialized = await _voiceService.initialize();
      if (!voiceInitialized) {
        _showError('Failed to initialize voice service');
      }
      
      // Initialize hybrid AI service
      final aiInitialized = await _aiService.initialize();
      if (!aiInitialized) {
        _showError('Failed to initialize AI service');
      }
      
      // Initialize Firebase sync
      final syncInitialized = await _syncService.initialize();
      if (!syncInitialized) {
        print('⚠️ Firebase sync not initialized (user may not be authenticated)');
      }
      
      print('✅ Voice interaction services initialized');
      
    } catch (e) {
      _showError('Service initialization failed: $e');
    }
  }

  void _startListeningFeedback() {
    _micController.repeat(reverse: true);
  }

  void _onVoiceDetected() {
    // Stop mic animation, start processing
    _micController.stop();
    _micController.forward();
  }

  void _startThinkingFeedback() {
    setState(() {
      _isProcessing = true;
    });
  }

  void _startSpeakingFeedback() {
    setState(() {
      _isProcessing = false;
    });
    
    // Animate response appearance
    _responseController.forward();
  }

  void _showSeriousWarning() {
    // Show urgent warning dialog
    _showUrgentDialog();
  }

  void _resetToIdle() {
    _micController.reset();
    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _startVoiceInteraction() async {
    try {
      // Start listening
      await _voiceService.startListening();
      
    } catch (e) {
      _showError('Failed to start voice interaction: $e');
    }
  }

  Future<void> _stopVoiceInteraction() async {
    try {
      // Stop listening and get transcription
      final result = await _voiceService.stopAndTranscribe();
      
      if (result.isValid) {
        // Process with AI
        await _processWithAI(result.text);
      } else if (result.isError) {
        _showError('Voice recognition error: ${result.text}');
      }
      
    } catch (e) {
      _showError('Failed to stop voice interaction: $e');
    }
  }

  Future<void> _processWithAI(String userInput) async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      // Get child context (for now, use default)
      final childContext = {
        'child_age': 5,
        'child_gender': 'male',
        'child_name': 'Child',
      };
      
      // Process with hybrid AI
      final result = await _aiService.processVoiceInput(
        userInput: userInput,
        childContext: childContext,
      );
      
      // Save interaction to database
      await _saveInteraction(userInput, result);
      
      // Update UI
      setState(() {
        _aiResponse = _formatAIResponse(result);
        _isProcessing = false;
      });
      
      // Trigger sync if available
      if (_syncService.isInitialized) {
        _triggerSync();
      }
      
    } catch (e) {
      _showError('AI processing failed: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _formatAIResponse(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    
    // Add symptoms
    if (result['symptoms'] != null) {
      buffer.writeln('🔍 **Symptoms Detected:**');
      final symptoms = result['symptoms'] as List;
      for (final symptom in symptoms) {
        buffer.writeln('• $symptom');
      }
      buffer.writeln();
    }
    
    // Add assessment
    if (result['assessment'] != null) {
      buffer.writeln('💭 **Assessment:**');
      buffer.writeln(result['assessment']);
      buffer.writeln();
    }
    
    // Add immediate advice
    if (result['immediate_advice'] != null) {
      buffer.writeln('💡 **Immediate Advice:**');
      buffer.writeln(result['immediate_advice']);
      buffer.writeln();
    }
    
    // Add follow-up questions
    if (result['follow_up_questions'] != null) {
      buffer.writeln('❓ **Follow-up Questions:**');
      final questions = result['follow_up_questions'] as List;
      for (int i = 0; i < questions.length; i++) {
        buffer.writeln('${i + 1}. ${questions[i]}');
      }
      buffer.writeln();
    }
    
    // Add when to seek care
    if (result['seek_care_when'] != null) {
      buffer.writeln('🚨 **Seek Care When:**');
      buffer.writeln(result['seek_care_when']);
    }
    
    return buffer.toString();
  }

  Future<void> _saveInteraction(String userInput, Map<String, dynamic> result) async {
    try {
      await _dbHelper.saveInteraction({
        'child_id': 1, // Default child ID
        'timestamp': DateTime.now().toIso8601String(),
        'user_input': userInput,
        'ai_response': result.toString(),
        'api_used': result['api_used'] ?? 'hybrid',
        'confidence': result['confidence'] ?? 0.0,
        'response_time_ms': 0, // TODO: Calculate actual response time
        'success': 1,
        'quality_score': 0.9, // TODO: Calculate actual quality score
      });
      
      print('✅ Interaction saved to database');
      
    } catch (e) {
      print('❌ Failed to save interaction: $e');
    }
  }

  Future<void> _triggerSync() async {
    try {
      setState(() {
        _isSyncing = true;
      });
      
      await _syncService.triggerManualSync();
      
      setState(() {
        _isSyncing = false;
      });
      
      _showSuccess('Data synced successfully');
      
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      _showError('Sync failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUrgentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Urgent Attention Required'),
          ],
        ),
        content: const Text(
          'This situation requires immediate medical attention. '
          'Please contact a healthcare provider or visit an emergency room.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Health Assistant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_syncService.isInitialized)
            IconButton(
              onPressed: _isSyncing ? null : _triggerSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sync Data',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Voice State Display
            _buildVoiceStateDisplay(),
            
            const SizedBox(height: 30),
            
            // Microphone Button
            _buildMicrophoneButton(),
            
            const SizedBox(height: 30),
            
            // Transcription Display
            if (_transcription.isNotEmpty) _buildTranscriptionDisplay(),
            
            const SizedBox(height: 20),
            
            // AI Response Display
            if (_aiResponse.isNotEmpty) _buildAIResponseDisplay(),
            
            const Spacer(),
            
            // Status Bar
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStateDisplay() {
    return VoiceStateAwareUI(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _getStateIcon(),
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              _getStateText(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_confidence > 0)
              Text(
                'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStateIcon() {
    switch (_currentVoiceState) {
      case VoiceState.idle:
        return Icons.mic_off;
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.activeListening:
        return Icons.mic;
      case VoiceState.thinking:
        return Icons.psychology;
      case VoiceState.speaking:
        return Icons.record_voice_over;
      case VoiceState.serious:
        return Icons.warning;
    }
  }

  String _getStateText() {
    switch (_currentVoiceState) {
      case VoiceState.idle:
        return 'Ready to Listen';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.activeListening:
        return 'Voice Detected!';
      case VoiceState.thinking:
        return 'Processing...';
      case VoiceState.speaking:
        return 'Speaking Response';
      case VoiceState.serious:
        return 'Urgent Attention Required';
    }
  }

  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTapDown: (_) => _micController.forward(),
      onTapUp: (_) => _micController.reverse(),
      onTapCancel: () => _micController.reverse(),
      child: AnimatedBuilder(
        animation: _micScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _micScaleAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _voiceService.isListening
                    ? _stopVoiceInteraction
                    : _startVoiceInteraction,
                icon: Icon(
                  _voiceService.isListening ? Icons.stop : Icons.mic,
                  size: 48,
                  color: Colors.white,
                ),
                tooltip: _voiceService.isListening ? 'Stop Listening' : 'Start Listening',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptionDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎤 What you said:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _transcription,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResponseDisplay() {
    return AnimatedBuilder(
      animation: _responseOpacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _responseOpacityAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🤖 AI Analysis:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _aiResponse,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isProcessing ? Icons.hourglass_empty : Icons.check_circle,
            color: _isProcessing ? Colors.orange : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isProcessing ? 'Processing...' : 'Ready',
            style: TextStyle(
              color: _isProcessing ? Colors.orange : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_syncService.isInitialized)
            Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  size: 16,
                  color: _isSyncing ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  _isSyncing ? 'Syncing...' : 'Synced',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSyncing ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _micController.dispose();
    _responseController.dispose();
    super.dispose();
  }
}
