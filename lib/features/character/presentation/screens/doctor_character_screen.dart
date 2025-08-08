import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/3d_character_service.dart';
import '../../../../services/stt_service.dart';
import '../../../../services/llm_service.dart';
import '../../../../services/tts_service.dart';
import '../../../../services/translation_service.dart';
import '../../../../core/services/character_interaction_engine.dart';

/// Full-screen 3D character experience with Dr. Healthie
class DoctorCharacterScreen extends ConsumerStatefulWidget {
  const DoctorCharacterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorCharacterScreen> createState() => _DoctorCharacterScreenState();
}

class _DoctorCharacterScreenState extends ConsumerState<DoctorCharacterScreen> {
  final ThreeDCharacterService _characterService = ThreeDCharacterService();
  final STTService _sttService = STTService();
  final LLMService _llmService = LLMService();
  final TTSService _ttsService = TTSService();
  final TranslationService _translationService = TranslationService();
  final CharacterInteractionEngine _characterEngine = CharacterInteractionEngine();

  WebViewController? _webViewController;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _recognizedText = '';
  String _aiResponse = '';
  String _detectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _initializeServices();
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
        _isInitialized = true;
      });

      print('🎭 All services initialized successfully');
    } catch (e) {
      print('❌ Error initializing services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with status
              _buildHeader(),
              
              // 3D Character WebView
              Expanded(
                child: _buildCharacterViewer(),
              ),
              
              // Voice interaction controls
              _buildVoiceControls(),
              
              // Status indicators
              _buildStatusIndicators(),
            ],
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Dr. Healthie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_off,
              color: _isListening ? Colors.green : Colors.white,
            ),
            onPressed: _toggleListening,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterViewer() {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading Dr. Healthie...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadHtmlString(_characterService.getCharacterHTML())
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (String url) {
                  _webViewController = WebViewController();
                  _characterService.setWebViewController(_webViewController!);
                  print('🎭 3D Character loaded successfully');
                },
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Voice input status
          if (_recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recognizedText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // AI response
          if (_aiResponse.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _aiResponse,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start/Stop Listening
              ElevatedButton.icon(
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(_isListening ? 'Stop' : 'Start Listening'),
                onPressed: _toggleListening,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),

              // Auto Process
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Auto Process'),
                onPressed: _isProcessing ? null : _startAutoProcess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
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

  bool get _isProcessing => _isListening || _isSpeaking;

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isProcessing) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _aiResponse = '';
    });

    // Change character state to listening
    await _characterService.changeState('listening');

    try {
      // Start listening with language detection
      final result = await _sttService.listenAndDetectLanguage();
      
      setState(() {
        _recognizedText = result['transcript'] ?? '';
        _detectedLanguage = result['language'] ?? 'en';
        _isListening = false;
      });

      print('🎭 Voice input: "$_recognizedText" (language: $_detectedLanguage)');

      // Process the input if we have text
      if (_recognizedText.isNotEmpty) {
        await _processVoiceInput();
      }

    } catch (e) {
      setState(() {
        _isListening = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopListening() async {
    await _sttService.stopListening();
    setState(() {
      _isListening = false;
    });
    await _characterService.changeState('idle');
  }

  Future<void> _startAutoProcess() async {
    if (_isProcessing) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _aiResponse = '';
    });

    await _characterService.changeState('listening');

    try {
      // Auto-detect and process
      final result = await _sttService.listenAndDetectLanguage();
      
      setState(() {
        _recognizedText = result['transcript'] ?? '';
        _detectedLanguage = result['language'] ?? 'en';
        _isListening = false;
      });

      if (_recognizedText.isNotEmpty) {
        await _processVoiceInput();
      }

    } catch (e) {
      setState(() {
        _isListening = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processVoiceInput() async {
    if (_recognizedText.isEmpty) return;

    setState(() {
      _isSpeaking = true;
    });

    // Change character state to thinking
    await _characterService.changeState('thinking');

    try {
      // Get AI response
      final aiResult = await _llmService.getAIResponse(
        'User said: $_recognizedText. Please provide a helpful medical response.',
        symptom: _recognizedText,
        originalTranscript: _recognizedText,
      );

      String response = aiResult['response'] ?? 'I understand. How can I help you further?';

      // Translate response if needed
      if (_detectedLanguage != 'en') {
        response = await _translationService.translateAIResponse(
          aiResponse: response,
          userLanguage: _detectedLanguage,
        );
      }

      setState(() {
        _aiResponse = response;
      });

      // Change character state to speaking and start lip sync
      await _characterService.changeState('speaking');
      await _characterService.startLipSync();

      // Speak the response
      final ttsLanguageCode = _ttsService.mapToTTSLanguage(_detectedLanguage);
      await _ttsService.speak(response, languageCode: ttsLanguageCode);

      // Stop lip sync and return to idle
      await _characterService.stopLipSync();
      await _characterService.changeState('idle');

      setState(() {
        _isSpeaking = false;
      });

    } catch (e) {
      setState(() {
        _isSpeaking = false;
        _aiResponse = 'Sorry, I encountered an error. Please try again.';
      });
      
      await _characterService.changeState('idle');
      
      print('❌ Error processing voice input: $e');
    }
  }

  @override
  void dispose() {
    _characterService.dispose();
    super.dispose();
  }
} 