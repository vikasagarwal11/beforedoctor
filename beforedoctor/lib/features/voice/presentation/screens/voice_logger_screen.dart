import 'package:flutter/material.dart';
import '../../../../services/stt_service.dart';
import '../../../../core/services/ai_prompt_service.dart';
import '../../../../services/llm_service.dart';
import '../../../../core/services/character_interaction_engine.dart';
import '../../../../core/services/logging_service.dart';

class VoiceLoggerScreen extends StatefulWidget {
  const VoiceLoggerScreen({Key? key}) : super(key: key);

  @override
  State<VoiceLoggerScreen> createState() => _VoiceLoggerScreenState();
}

class _VoiceLoggerScreenState extends State<VoiceLoggerScreen> {
  final _symptomController = TextEditingController();
  final STTService _stt = STTService();
  final AIPromptService _promptService = AIPromptService();
  final LLMService _llmService = LLMService();
  final CharacterInteractionEngine _characterEngine = CharacterInteractionEngine.instance;
  final LoggingService _loggingService = LoggingService();

  String _recognizedText = '';
  String _aiResponse = '';
  bool _isProcessing = false;
  bool _isListening = false;
  String _selectedModel = 'auto';
  Map<String, dynamic> _modelPerformance = {};
  Map<String, dynamic> _modelRecommendation = {};

  final Map<String, String> _childMetadata = {
    'child_name': 'Ava',
    'child_age': '4',
    'gender': 'female',
    'symptom_duration': '2 days',
    'temperature': '',
    'associated_symptoms': '',
    'medications': '',
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _stt.initialize();
    await _promptService.loadTemplates();
    await _characterEngine.initialize();
    await _llmService.initialize();
    _updateModelPerformance();
  }

  void _updateModelPerformance() {
    setState(() {
      _modelPerformance = _llmService.getModelPerformanceSummary();
      _modelRecommendation = _llmService.getModelRecommendation();
    });
  }

  void _startListening() {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _aiResponse = '';
    });

    _stt.startListening(
      onResult: (text) {
        setState(() {
          _recognizedText = text;
          _symptomController.text = text;
        });
      },
      onDone: () {
        setState(() => _isListening = false);
        // Auto-process after voice input
        if (_recognizedText.isNotEmpty) {
          _processSymptom(_recognizedText);
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _aiResponse = 'Voice input error: $error';
        });
      },
    );
  }

  void _stopListening() {
    _stt.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _processSymptom(String symptom) async {
    if (symptom.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _aiResponse = '';
    });

    try {
      // Start character thinking animation
      _characterEngine.startThinking();

      // Build prompt using AIPromptService
      final prompt = _promptService.buildLLMPrompt(symptom, _childMetadata);
      if (prompt.isEmpty) {
        setState(() {
          _aiResponse = 'No template found for "$symptom".';
          _isProcessing = false;
        });
        return;
      }

      // Call AI service with dynamic model selection
      String llmResponse;
      String modelUsed;
      int latencyMs = 0;

      final startTime = DateTime.now();
      
      switch (_selectedModel) {
        case 'auto':
          llmResponse = await _llmService.getAIResponse(prompt);
          modelUsed = 'auto_selected';
          break;
        case 'openai':
          llmResponse = await _llmService.callOpenAI(prompt);
          modelUsed = 'openai';
          break;
        case 'grok':
          llmResponse = await _llmService.callGrok(prompt);
          modelUsed = 'grok';
          break;
        case 'fallback':
        default:
          llmResponse = _llmService.generateFallbackResponse(prompt);
          modelUsed = 'fallback';
          break;
      }

      latencyMs = DateTime.now().difference(startTime).inMilliseconds;

      // React to symptom and speak the result
      _characterEngine.reactToSymptom(symptom);
      await _characterEngine.speakWithAnimation(llmResponse);

      // Log the interaction
      await _loggingService.logInteraction(
        interactionType: 'voice_log',
        symptomCategory: symptom,
        modelUsed: modelUsed,
        responseTime: latencyMs,
        success: llmResponse.isNotEmpty,
        metadata: {
          'prompt': prompt,
          'response_length': llmResponse.length,
          'child_name': _childMetadata['child_name'],
          'child_age': _childMetadata['child_age'],
          'child_gender': _childMetadata['gender'],
          'voice_confidence': _stt.confidence,
        },
      );

      // Update model performance display
      _updateModelPerformance();

      setState(() {
        _aiResponse = llmResponse;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _aiResponse = 'Error processing request: $e';
        _isProcessing = false;
      });
      
      // Log error
      await _loggingService.logInteraction(
        interactionType: 'voice_log',
        symptomCategory: 'error',
        modelUsed: _selectedModel,
        responseTime: 0,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  void _showModelSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Model Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedModel,
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('🔄 Auto-Select (Recommended)')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI GPT-4o')),
                DropdownMenuItem(value: 'grok', child: Text('xAI Grok')),
                DropdownMenuItem(value: 'fallback', child: Text('Local Fallback')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedModel = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_modelRecommendation.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 AI Recommendation:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Model: ${_modelRecommendation['recommendedModel']?.toUpperCase() ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                    Text(
                      'Confidence: ${_modelRecommendation['confidence'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _stt.dispose();
    _characterEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("🎤 BeforeDoctor: Voice Assistant"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showModelSelectionDialog,
            tooltip: 'Model Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Model Selection Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Model:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedModel == 'auto' ? '🔄 Auto-Select' : _selectedModel.toUpperCase(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (_modelRecommendation.isNotEmpty) ...[
                          Text(
                            'Recommended: ${_modelRecommendation['recommendedModel']?.toUpperCase() ?? 'N/A'}',
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showModelSelectionDialog,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Enter or speak a symptom:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isListening ? _stopListening : _startListening,
                        icon: Icon(_isListening ? Icons.stop : Icons.mic),
                        color: _isListening ? Colors.red : Colors.blue,
                        tooltip: _isListening ? 'Stop Recording' : 'Start Recording',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _symptomController,
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening...' : 'e.g., fever, cough, vomiting',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isListening
                        ? const Icon(Icons.mic, color: Colors.red)
                        : null,
                    ),
                    maxLines: 3,
                    enabled: !_isListening,
                  ),
                  if (_isListening) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Listening... Tap mic to stop',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening ? 'Stop Recording' : '🎤 Start Voice'),
                    onPressed: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isProcessing || _isListening) ? null : () => _processSymptom(
                      _recognizedText.isNotEmpty ? _recognizedText : _symptomController.text,
                    ),
                    icon: _isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ) 
                      : const Icon(Icons.send),
                    label: Text(_isProcessing ? 'Processing...' : '🤖 Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Voice Recognition Display
            if (_recognizedText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'You said:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recognizedText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // AI Response Display
            if (_aiResponse.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🤖 AI Response:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedModel.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiResponse,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Clear Button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _aiResponse = '';
                  _recognizedText = '';
                  _symptomController.clear();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 