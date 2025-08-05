import 'package:flutter/material.dart';
import '../../../../core/services/ai_prompt_service.dart';
import '../../../../services/llm_service.dart';
import '../../../../services/stt_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/character_interaction_engine.dart';

class VoiceLoggerScreen extends StatefulWidget {
  const VoiceLoggerScreen({Key? key}) : super(key: key);

  @override
  _VoiceLoggerScreenState createState() => _VoiceLoggerScreenState();
}

class _VoiceLoggerScreenState extends State<VoiceLoggerScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final AIPromptService _promptService = AIPromptService();
  final LLMService _llmService = LLMService();
  final STTService _sttService = STTService();
  final LoggingService _loggingService = LoggingService();
  final CharacterInteractionEngine _characterEngine = CharacterInteractionEngine.instance;

  String _response = '';
  bool _isLoading = false;
  bool _isListening = false;
  String _selectedModel = 'auto'; // 'auto', 'openai', 'grok', 'fallback'
  String _selectedInputMode = 'text'; // 'text', 'voice'
  Map<String, dynamic> _modelPerformance = {};
  Map<String, dynamic> _modelRecommendation = {};

  // Sample child metadata – eventually replace with real input or profile
  final Map<String, String> _childMetadata = {
    'child_age': '5',
    'gender': 'male',
    'temperature': '',
    'duration': '',
    'associated_symptoms': '',
    'medications': '',
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _promptService.loadTemplates();
    await _characterEngine.initialize();
    await _llmService.initialize();
    await _sttService.initialize();
    _updateModelPerformance();
  }

  void _updateModelPerformance() {
    setState(() {
      _modelPerformance = _llmService.getModelPerformanceSummary();
      _modelRecommendation = _llmService.getModelRecommendation();
    });
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _response = '';
    });

    try {
      await _sttService.startListening(
        onResult: (text) {
          setState(() {
            _symptomController.text = text;
            _isListening = false;
          });
          // Auto-submit after voice input
          _handleSubmit();
        },
        onDone: () {
          setState(() {
            _isListening = false;
          });
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            _response = 'Voice input error: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _response = 'Failed to start voice input: $e';
      });
    }
  }

  void _stopVoiceInput() {
    _sttService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _handleSubmit() async {
    final symptom = _symptomController.text.trim().toLowerCase();
    if (symptom.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      // Build prompt using AIPromptService
      final prompt = _promptService.buildLLMPrompt(symptom, _childMetadata);
      if (prompt.isEmpty) {
        setState(() {
          _response = 'No template found for "$symptom".';
          _isLoading = false;
        });
        return;
      }

      // Start character thinking animation
      _characterEngine.startThinking();

      // Call AI service with dynamic model selection
      String llmResponse;
      String modelUsed;
      int latencyMs = 0;

      final startTime = DateTime.now();
      
      switch (_selectedModel) {
        case 'auto':
          // Use the new getAIResponse method with auto-selection
          llmResponse = await _llmService.getAIResponse(prompt);
          modelUsed = 'auto_selected';
          break;
        case 'openai':
          // Use specific model selection
          llmResponse = await _llmService.callOpenAI(prompt);
          modelUsed = 'openai';
          break;
        case 'grok':
          // Use specific model selection
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

      // Log the interaction using correct method signature
      await _loggingService.logInteraction(
        interactionType: _selectedInputMode == 'voice' ? 'voice_log' : 'text_log',
        symptomCategory: symptom,
        modelUsed: modelUsed,
        responseTime: latencyMs,
        success: llmResponse.isNotEmpty,
        metadata: {
          'prompt': prompt,
          'response_length': llmResponse.length,
          'child_age': _childMetadata['child_age'],
          'child_gender': _childMetadata['gender'],
          'input_mode': _selectedInputMode,
          'voice_confidence': _sttService.confidence,
        },
      );

      // Update model performance display
      _updateModelPerformance();

      setState(() {
        _response = llmResponse;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _response = 'Error processing request: $e';
        _isLoading = false;
      });
      
      // Log error
      await _loggingService.logInteraction(
        interactionType: _selectedInputMode == 'voice' ? 'voice_log' : 'text_log',
        symptomCategory: 'error',
        modelUsed: _selectedModel,
        responseTime: 0,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  void _showInputModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎤 Input Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedInputMode,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('📝 Text Input')),
                DropdownMenuItem(value: 'voice', child: Text('🎤 Voice Input')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedInputMode = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
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
                    '💡 Voice Input Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available: ${_sttService.isAvailable ? '✅ Yes' : '❌ No'}',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                  Text(
                    'Listening: ${_sttService.isListening ? '🔴 Active' : '⚪ Inactive'}',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
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

  void _showModelPerformanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Model Performance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_modelPerformance.isNotEmpty) ...[
                _buildModelPerformanceCard('OpenAI', _modelPerformance['openai']),
                const SizedBox(height: 12),
                _buildModelPerformanceCard('Grok', _modelPerformance['grok']),
                const SizedBox(height: 16),
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
                      Text(
                        '🎯 Recommended: ${_modelPerformance['recommendedModel']?.toUpperCase() ?? 'N/A'}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on success rate, latency, and recent performance',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text('No performance data available yet.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await _llmService.resetModelStats();
              _updateModelPerformance();
              Navigator.of(context).pop();
            },
            child: const Text('Reset Stats'),
          ),
        ],
      ),
    );
  }

  Widget _buildModelPerformanceCard(String modelName, Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            modelName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Success Rate: ${(stats['successRate'] * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Avg Latency: ${stats['avgLatency'].toStringAsFixed(0)}ms',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Calls: ${stats['totalCalls']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Score: ${stats['weightedScore'].toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('🎤 Voice Logger'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showModelPerformanceDialog,
            tooltip: 'Model Performance',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showModelSelectionDialog,
            tooltip: 'Model Settings',
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _selectedInputMode == 'text' ? _startVoiceInput : _stopVoiceInput,
            tooltip: _selectedInputMode == 'text' ? 'Start Voice Input' : 'Stop Voice Input',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showInputModeDialog,
            tooltip: 'Input Mode',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: Column(
                children: [
                  Row(
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
                  const Divider(),
                  Row(
                    children: [
                      Icon(
                        _selectedInputMode == 'voice' ? Icons.mic : Icons.text_fields,
                        color: _selectedInputMode == 'voice' ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Input Mode:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _selectedInputMode == 'voice' ? '🎤 Voice Input' : '📝 Text Input',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Status: ${_sttService.isAvailable ? '✅ Available' : '❌ Unavailable'}',
                              style: TextStyle(fontSize: 10, color: _sttService.isAvailable ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _showInputModeDialog,
                        child: const Text('Change'),
                      ),
                    ],
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
                        'Enter Symptom Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_selectedInputMode == 'voice') ...[
                        IconButton(
                          onPressed: _isListening ? _stopVoiceInput : _startVoiceInput,
                          icon: Icon(_isListening ? Icons.stop : Icons.mic),
                          color: _isListening ? Colors.red : Colors.blue,
                          tooltip: _isListening ? 'Stop Recording' : 'Start Recording',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _symptomController,
                    decoration: InputDecoration(
                      hintText: _selectedInputMode == 'voice' 
                        ? 'Tap mic to start voice input...' 
                        : 'e.g., fever, cough, vomiting',
                      border: const OutlineInputBorder(),
                      suffixIcon: _selectedInputMode == 'voice' && _isListening
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

            // Submit Button
            ElevatedButton.icon(
              onPressed: (_isLoading || _isListening) ? null : _handleSubmit,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) 
                : const Icon(Icons.send),
              label: Text(_isLoading ? 'Processing...' : 'Generate & Speak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Response Display
            if (_response.isNotEmpty) ...[
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
                      _response,
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
                  _response = '';
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

  @override
  void dispose() {
    _sttService.dispose();
    _characterEngine.dispose();
    super.dispose();
  }
} 