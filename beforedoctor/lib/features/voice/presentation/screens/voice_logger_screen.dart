import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_prompt_service.dart';
import '../../../../core/services/voice_input_service.dart';

class VoiceLoggerScreen extends ConsumerStatefulWidget {
  const VoiceLoggerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceLoggerScreen> createState() => _VoiceLoggerScreenState();
}

class _VoiceLoggerScreenState extends ConsumerState<VoiceLoggerScreen> {
  late VoiceInputService _voiceService;
  late AIPromptService _promptService;
  
  bool _isListening = false;
  String _transcription = '';
  String _detectedSymptom = '';
  String _generatedPrompt = '';
  List<String> _followUpQuestions = [];
  
  // Child metadata
  Map<String, String> _childMetadata = {
    'child_age': '4',
    'gender': 'female',
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
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize voice service
      _voiceService = VoiceInputService.instance;
      await _voiceService.initialize();
      
      // Initialize AI prompt service
      _promptService = AIPromptService();
      await _promptService.loadTemplates();
      
      print('✅ Voice logger services initialized successfully');
    } catch (e) {
      print('❌ Error initializing voice logger services: $e');
    }
  }

  void _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _transcription = '';
      _detectedSymptom = '';
      _generatedPrompt = '';
      _followUpQuestions.clear();
    });

    // Use simulated voice input with text from controller
    final inputText = _textController.text.isNotEmpty 
        ? _textController.text 
        : "My 4-year-old daughter has a fever of 102 degrees";
    
    await _voiceService.simulateVoiceInput(inputText);
    
    // Listen to the transcription stream
    _voiceService.transcriptionStream.listen((transcription) {
      setState(() {
        _transcription = transcription;
      });
    });

    // Listen to processing stream to know when to stop
    _voiceService.processingStream.listen((isProcessing) {
      if (!isProcessing && _isListening) {
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  void _stopListening() {
    _voiceService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  void _processTranscription() {
    if (_transcription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transcription to process.')),
      );
      return;
    }

    // Extract symptom using our voice service
    final symptoms = _voiceService.detectSymptoms(_transcription);
    
    if (symptoms.isNotEmpty) {
      final matchedSymptom = symptoms.first;
      setState(() {
        _detectedSymptom = matchedSymptom;
      });

      // Generate AI prompt
      final prompt = _promptService.buildLLMPrompt(matchedSymptom, _childMetadata);
      final followUpQuestions = _promptService.getFollowUpQuestions(matchedSymptom);
      
      setState(() {
        _generatedPrompt = prompt;
        _followUpQuestions = followUpQuestions;
      });

      // Show results dialog
      _showResultsDialog(matchedSymptom, prompt, followUpQuestions);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching symptom found.')),
      );
    }
  }

  void _showResultsDialog(String symptom, String prompt, List<String> followUpQuestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🏥 Results for $symptom'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Detected Symptom: $symptom', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Generated Prompt:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(prompt, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              if (followUpQuestions.isNotEmpty) ...[
                const Text('Follow-up Questions:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(followUpQuestions.map((question) => 
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
                hintText: '4',
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
        title: const Text('🎤 Voice Logger'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Child Metadata Display
            Container(
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

            const SizedBox(height: 20),

            // Input Area
            Container(
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

            const SizedBox(height: 20),

            // Voice Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
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
                  onPressed: _transcription.isNotEmpty ? _processTranscription : null,
                  icon: const Icon(Icons.psychology),
                  label: const Text('Process'),
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

            const SizedBox(height: 20),

            // Transcription Display
            Container(
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
                        _isListening ? 'Listening...' : 'Ready',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isListening ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _transcription.isEmpty ? 'Say something...' : _transcription,
                    style: TextStyle(
                      fontSize: 16,
                      color: _transcription.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Results Display
            if (_detectedSymptom.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏥 Detected Symptom: $_detectedSymptom',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (_generatedPrompt.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '🤖 Generated Prompt:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedPrompt,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (_followUpQuestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '❓ Follow-up Questions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
            ],

            const Spacer(),

            // Clear Button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _transcription = '';
                  _detectedSymptom = '';
                  _generatedPrompt = '';
                  _followUpQuestions.clear();
                  _textController.clear();
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