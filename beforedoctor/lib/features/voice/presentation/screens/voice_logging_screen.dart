import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/services/ai_prompt_service.dart';

class VoiceLoggingScreen extends ConsumerStatefulWidget {
  const VoiceLoggingScreen({super.key});

  @override
  ConsumerState<VoiceLoggingScreen> createState() => _VoiceLoggingScreenState();
}

class _VoiceLoggingScreenState extends ConsumerState<VoiceLoggingScreen>
    with TickerProviderStateMixin {
  // Services
  late VoiceInputService _voiceService;
  late AIPromptService _aiPromptService;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;

  // State variables
  String _currentTranscription = '';
  double _currentConfidence = 0.0;
  bool _isListening = false;
  bool _isProcessing = false;
  List<String> _detectedSymptoms = [];
  String _generatedPrompt = '';
  List<String> _followUpQuestions = [];
  Map<String, String> _childMetadata = {
    'child_age': '3',
    'gender': 'male',
    'temperature': '',
    'duration': '',
    'associated_symptoms': '',
    'medications': '',
  };

  // Text controller for manual input
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeServices();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize voice service
      _voiceService = VoiceInputService.instance;
      await _voiceService.initialize();
      
      // Initialize AI prompt service
      _aiPromptService = AIPromptService();
      await _aiPromptService.loadTemplates();
      
      // Listen to voice service streams
      _voiceService.transcriptionStream.listen(_onTranscriptionUpdate);
      _voiceService.confidenceStream.listen(_onConfidenceUpdate);
      _voiceService.listeningStream.listen(_onListeningUpdate);
      _voiceService.processingStream.listen(_onProcessingUpdate);
      
      print('✅ Services initialized successfully');
    } catch (e) {
      print('❌ Error initializing services: $e');
    }
  }

  void _onTranscriptionUpdate(String transcription) {
    if (!mounted) return;
    setState(() {
      _currentTranscription = transcription;
    });
  }

  void _onConfidenceUpdate(double confidence) {
    if (!mounted) return;
    setState(() {
      _currentConfidence = confidence;
    });
  }

  void _onListeningUpdate(bool isListening) {
    if (!mounted) return;
    setState(() {
      _isListening = isListening;
    });

    if (isListening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  void _onProcessingUpdate(bool isProcessing) {
    if (!mounted) return;
    setState(() {
      _isProcessing = isProcessing;
    });
  }

  Future<void> _startVoiceLogging() async {
    if (_isListening) return;

    setState(() {
      _currentTranscription = '';
      _currentConfidence = 0.0;
      _detectedSymptoms.clear();
      _generatedPrompt = '';
      _followUpQuestions.clear();
      _isListening = true;
    });

    // Use simulated voice input for now
    final sampleText = _textController.text.isNotEmpty 
        ? _textController.text 
        : "My 3-year-old son has a fever of 102 degrees for 2 days";
    
    await _voiceService.simulateVoiceInput(sampleText);
  }

  Future<void> _stopVoiceLogging() async {
    if (!_isListening) return;
    
    setState(() {
      _isListening = false;
    });
    
    _onListeningUpdate(false);
    _onProcessingUpdate(true);
    
    // Process the transcription
    await _processSymptomData();
  }

  Future<void> _processSymptomData() async {
    try {
      if (_currentTranscription.isEmpty) return;

      // Extract symptoms from transcription
      final symptoms = _voiceService.detectSymptoms(_currentTranscription);
      
      setState(() {
        _detectedSymptoms = symptoms;
      });

      if (symptoms.isNotEmpty) {
        // Generate AI prompt for the first detected symptom
        final primarySymptom = symptoms.first;
        final prompt = _aiPromptService.buildLLMPrompt(primarySymptom, _childMetadata);
        final followUpQuestions = _aiPromptService.getFollowUpQuestions(primarySymptom);
        
        setState(() {
          _generatedPrompt = prompt;
          _followUpQuestions = followUpQuestions;
        });
        
        print('🏥 Generated prompt for $primarySymptom');
      }
    } catch (e) {
      print('❌ Error processing symptom data: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showTreatmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏥 AI-Generated Treatment Recommendation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_generatedPrompt.isNotEmpty) ...[
                const Text('Generated Prompt:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_generatedPrompt, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
              ],
              if (_followUpQuestions.isNotEmpty) ...[
                const Text('Follow-up Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(_followUpQuestions.map((question) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $question'),
                  )
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChildMetadataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👶 Child Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: '3',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _childMetadata['child_age'] = value,
              controller: TextEditingController(text: _childMetadata['child_age']),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Gender',
              ),
              value: _childMetadata['gender'],
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _childMetadata['gender'] = value;
                  });
                }
              },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('🎤 Voice Symptom Logger'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.child_care),
            onPressed: _showChildMetadataDialog,
            tooltip: 'Child Information',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Child Metadata Display
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.child_care, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${_childMetadata['child_age']}-year-old ${_childMetadata['gender']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _showChildMetadataDialog,
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),

            // Manual Input Area
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Symptom Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., My child has a fever of 102 degrees',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            // Character Animation Area
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _isListening
                    ? AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 100 + (_pulseController.value * 20),
                            height: 100 + (_pulseController.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                            child: const Icon(
                              Icons.mic,
                              size: 50,
                              color: Colors.blue,
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.mic_off,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),

            // Transcription Area
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                      Icon(
                        _isListening ? Icons.record_voice_over : Icons.mic,
                        color: _isListening ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isListening ? 'Processing...' : 'Ready to process',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isListening ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentTranscription.isEmpty ? 'Enter text above and tap "Start Processing" to analyze symptoms...' : _currentTranscription,
                    style: TextStyle(
                      fontSize: 16,
                      color: _currentTranscription.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                  if (_currentConfidence > 0) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _currentConfidence,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _currentConfidence > 0.8 ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(_currentConfidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentConfidence > 0.8 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Detected Symptoms
            if (_detectedSymptoms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏥 Detected Symptoms:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _detectedSymptoms.map((symptom) {
                        return Chip(
                          label: Text(symptom.replaceAll('_', ' ')),
                          backgroundColor: Colors.green[100],
                          labelStyle: const TextStyle(color: Colors.green),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // AI Generated Prompt
            if (_generatedPrompt.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤖 AI-Generated Prompt:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedPrompt,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Processing Indicator
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Processing symptoms with AI...',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isListening ? _stopVoiceLogging : _startVoiceLogging,
                      icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
                      label: Text(_isListening ? 'Stop Processing' : 'Start Processing'),
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
                  ElevatedButton.icon(
                    onPressed: _isListening || _isProcessing ? null : () {
                      setState(() {
                        _currentTranscription = '';
                        _currentConfidence = 0.0;
                        _detectedSymptoms.clear();
                        _generatedPrompt = '';
                        _followUpQuestions.clear();
                        _textController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _generatedPrompt.isNotEmpty ? () => _showTreatmentDialog() : null,
                    icon: const Icon(Icons.medical_services),
                    label: const Text('AI Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }
} 