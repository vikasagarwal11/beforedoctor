import 'package:flutter/material.dart';
import '../../../../services/stt_service.dart';
import '../../../../core/services/ai_prompt_service.dart';
import '../../../../services/llm_service.dart';
import '../../../../core/services/character_interaction_engine.dart';
import '../../../../services/usage_logger_service.dart';
import '../../../../services/sheet_uploader_example.dart';
import '../../../../core/services/symptom_extraction_service.dart';
import '../../../../core/services/multi_symptom_analyzer.dart';
import '../../../../core/services/treatment_recommendation_service.dart';
import '../../../../services/translation_service.dart';
import '../../../../services/tts_service.dart';

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
  final UsageLoggerService _usageLogger = UsageLoggerService();
  final SymptomExtractionService _symptomExtractor = SymptomExtractionService();
  final MultiSymptomAnalyzer _multiSymptomAnalyzer = MultiSymptomAnalyzer();
  final TreatmentRecommendationService _treatmentService = TreatmentRecommendationService();
  final TranslationService _translationService = TranslationService();
  final TTSService _ttsService = TTSService();

  String _recognizedText = '';
  String _aiResponse = '';
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isUploading = false;
  String _selectedModel = 'auto';
  Map<String, dynamic> _modelPerformance = {};
  Map<String, dynamic> _modelRecommendation = {};
  Map<String, dynamic> _analytics = {};

  // Multi-symptom analysis results
  MultiSymptomAnalysis? _multiSymptomAnalysis;
  SymptomExtractionResult? _symptomExtractionResult;
  TreatmentRecommendation? _treatmentRecommendation;

  // Language support
  String _currentLanguage = 'en';
  String _detectedLanguage = 'en';

  // Enhanced child metadata with better structure
  final Map<String, String> _childMetadata = {
    'child_name': 'Vihaan',
    'child_age': '4',
    'child_gender': 'male',
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
    await _usageLogger.init();
    await _ttsService.initTTS();
    
    // Initialize translation service and preload common languages
    await _translationService.preloadCommonLanguages();
    
    _updateModelPerformance();
    _updateAnalytics();
  }

  void _updateModelPerformance() {
    setState(() {
      _modelPerformance = _llmService.getModelPerformanceSummary();
      _modelRecommendation = _llmService.getModelRecommendation();
    });
  }

  void _updateAnalytics() async {
    final analytics = await _usageLogger.getAnalytics();
    setState(() {
      _analytics = analytics;
    });
  }

  void _startListening() {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _aiResponse = '';
      _multiSymptomAnalysis = null;
      _symptomExtractionResult = null;
      _treatmentRecommendation = null;
    });

    _stt.startListening(
      onResult: (text, detectedLanguage) {
        setState(() {
          _recognizedText = text;
          _symptomController.text = text;
          _detectedLanguage = detectedLanguage; // Store detected language from STT
        });
        print('🌍 Voice input detected language: $detectedLanguage for: "$text"');
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('❌ Voice recognition error: $error'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  void _stopListening() async {
    await _stt.stopListening();
    setState(() => _isListening = false);
  }

  // Enhanced symptom processing with treatment recommendations
  Future<void> _processSymptom(String symptom) async {
    if (symptom.trim().isEmpty) {
      _showUserFeedback('Please enter a symptom', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _aiResponse = '';
      _multiSymptomAnalysis = null;
      _symptomExtractionResult = null;
      _treatmentRecommendation = null;
    });

    try {
      // Start character thinking animation
      _characterEngine.startThinking();

      // Step 0: Process language and translate if needed (language already detected by STT)
      String processedSymptom = symptom;
      
      if (_detectedLanguage != 'en') {
        // Translate user input to English for AI processing
        processedSymptom = await _translationService.translateUserInput(
          userInput: symptom,
          userLanguage: _detectedLanguage,
        );
        print('🌍 Translated user input: "$symptom" → "$processedSymptom" (detected: $_detectedLanguage)');
      }

      // Step 1: Extract symptoms from voice input
      final extractionResult = await _symptomExtractor.extractSymptoms(processedSymptom);
      setState(() {
        _symptomExtractionResult = extractionResult;
      });

      if (!extractionResult.hasSymptoms) {
        setState(() {
          _aiResponse = 'No symptoms detected. Please try describing the symptoms more clearly.';
          _isProcessing = false;
        });
        _showUserFeedback('No symptoms detected', isError: true);
        return;
      }

      // Step 2: Perform multi-symptom analysis
      final analysis = await _multiSymptomAnalyzer.analyzeSymptoms(
        symptoms: extractionResult.symptoms,
        childAge: _childMetadata['child_age']!,
        childGender: _childMetadata['child_gender']!,
        temperature: extractionResult.context?['temperature'],
        duration: _childMetadata['symptom_duration'],
      );

      setState(() {
        _multiSymptomAnalysis = analysis;
      });

      // Step 3: Generate treatment recommendations
      final treatmentRecommendation = await _treatmentService.generateRecommendations(
        symptoms: extractionResult.symptoms,
        childAge: _childMetadata['child_age']!,
        childGender: _childMetadata['child_gender']!,
        severityScore: analysis.severityScore,
        emergencyFlags: analysis.emergencyFlags,
        temperature: extractionResult.context?['temperature'],
        duration: _childMetadata['symptom_duration'],
      );

      setState(() {
        _treatmentRecommendation = treatmentRecommendation;
      });

      // Step 4: Build comprehensive prompt using AIPromptService
      final prompt = _buildComprehensivePrompt(processedSymptom, extractionResult, analysis, treatmentRecommendation);
      
      // Step 5: Call AI service with dynamic model selection
      String llmResponse;
      String modelUsed;
      int latencyMs = 0;
      double score = 0.0;

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
      
      // Calculate a simple score based on response quality
      score = _calculateResponseScore(llmResponse, latencyMs);

      // Step 6: Translate AI response to user's language if needed
      String finalResponse = llmResponse;
      if (_detectedLanguage != 'en') {
        finalResponse = await _translationService.translateAIResponse(
          aiResponse: llmResponse,
          userLanguage: _detectedLanguage,
        );
        print('🌍 Translated AI response to $_detectedLanguage: "${llmResponse.substring(0, llmResponse.length > 50 ? 50 : llmResponse.length)}..." → "${finalResponse.substring(0, finalResponse.length > 50 ? 50 : finalResponse.length)}..."');
      }

      // React to symptom and speak the result
      _characterEngine.reactToSymptom(symptom);
      await _characterEngine.speakWithAnimation(finalResponse, detectedLanguage: _detectedLanguage);
      
      // Additional direct TTS call with language mapping
      final ttsLanguageCode = _ttsService.mapToTTSLanguage(_detectedLanguage);
      await _ttsService.speak(finalResponse, languageCode: ttsLanguageCode);

      // Log the interaction using UsageLoggerService
      await _usageLogger.logInteraction(
        symptom: symptom,
        promptUsed: prompt,
        modelUsed: modelUsed,
        aiResponse: finalResponse,
        latencyMs: latencyMs,
        success: finalResponse.isNotEmpty,
        score: score,
        interactionType: 'voice_log',
        childAge: _childMetadata['child_age'],
        childGender: _childMetadata['child_gender'],
        voiceConfidence: _stt.confidence,
      );

      // Update model performance display
      _updateModelPerformance();
      _updateAnalytics();

      setState(() {
        _aiResponse = finalResponse;
        _isProcessing = false;
      });

      // Show success message
      _showUserFeedback('✅ Comprehensive analysis complete!', isError: false);

    } catch (e) {
      setState(() {
        _aiResponse = 'Error processing request: $e';
        _isProcessing = false;
      });
      
      // Log error
      await _usageLogger.logInteraction(
        symptom: 'error',
        promptUsed: '',
        modelUsed: _selectedModel,
        aiResponse: '',
        latencyMs: 0,
        success: false,
        score: 0.0,
        interactionType: 'voice_log',
        childAge: _childMetadata['child_age'],
        childGender: _childMetadata['child_gender'],
        voiceConfidence: _stt.confidence,
        errorMessage: e.toString(),
      );

      // Show error message
      _showUserFeedback('❌ Failed to get AI response', isError: true);
    }
  }

  // Build comprehensive prompt including treatment recommendations
  String _buildComprehensivePrompt(
    String originalInput,
    SymptomExtractionResult extractionResult,
    MultiSymptomAnalysis analysis,
    TreatmentRecommendation treatmentRecommendation,
  ) {
    final symptoms = extractionResult.symptoms.join(', ');
    final conditions = analysis.potentialConditions.take(3).map((c) => c.condition).join(', ');
    final severity = analysis.severityScore.toStringAsFixed(1);
    final emergencyFlags = analysis.emergencyFlags.isNotEmpty ? 'EMERGENCY: ${analysis.emergencyFlags.join(', ')}' : 'None';
    
    // Add treatment information
    final treatments = treatmentRecommendation.treatments.map((t) => t.condition).join(', ');
    final medications = treatmentRecommendation.medications.map((m) => m.name).join(', ');
    
    return '''
Child Information:
- Age: ${_childMetadata['child_age']} years
- Gender: ${_childMetadata['child_gender']}
- Duration: ${_childMetadata['symptom_duration']}

Voice Input: "$originalInput"

Extracted Symptoms: $symptoms
Potential Conditions: $conditions
Severity Score: $severity/10
Emergency Flags: $emergencyFlags

Treatment Analysis:
- Recommended Treatments: $treatments
- Medications: $medications
- Home Care: ${treatmentRecommendation.homeCare.take(3).join(', ')}
- When to Seek Care: ${treatmentRecommendation.whenToSeekCare.take(3).join(', ')}

Please provide:
1. Immediate recommendations based on severity and treatments
2. Medication guidance with safety considerations
3. Home care instructions
4. When to seek medical attention
5. Warning signs to watch for
6. Follow-up recommendations

Focus on pediatric-specific guidance, age-appropriate recommendations, and evidence-based treatments.
''';
  }

  // Enhanced user feedback system
  void _showUserFeedback(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double _calculateResponseScore(String response, int latencyMs) {
    double score = 0.0;
    
    // Base score for having a response
    if (response.isNotEmpty) score += 0.3;
    
    // Score based on response length (more detailed = better)
    if (response.length > 100) score += 0.2;
    if (response.length > 200) score += 0.1;
    
    // Score based on latency (faster = better)
    if (latencyMs < 2000) score += 0.2;
    if (latencyMs < 1000) score += 0.1;
    
    // Score based on voice confidence
    score += _stt.confidence * 0.2;
    
    return score.clamp(0.0, 1.0);
  }

  Future<void> _uploadToGoogleSheets() async {
    setState(() {
      _isUploading = true;
    });

    try {
      await SheetUploaderExample.setupAndUpload();
      _showUserFeedback('✅ Synced with Google Sheets!', isError: false);
    } catch (e) {
      _showUserFeedback('❌ Failed to upload logs: $e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('📊 Usage Analytics'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_analytics.isNotEmpty) ...[
                _buildAnalyticsCard('Total Interactions', _analytics['total_interactions'].toString()),
                _buildAnalyticsCard('Success Rate', '${_analytics['success_rate'].toStringAsFixed(1)}%'),
                _buildAnalyticsCard('Average Latency', '${_analytics['average_latency_ms'].toStringAsFixed(0)}ms'),
                _buildAnalyticsCard('Average Score', _analytics['average_score'].toStringAsFixed(3)),
                const SizedBox(height: 16),
                const Text(
                  'Model Usage:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(_analytics['model_usage'] as Map<String, int>).entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
              ] else ...[
                const Text('No analytics data available yet.'),
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
              await _usageLogger.clearLogs();
              _updateAnalytics();
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showModelSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('🔧 Model Selection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: InputDecoration(
                labelText: 'Select AI Model',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          '💡 AI Recommendation:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Model: ${_modelRecommendation['recommendedModel']?.toUpperCase() ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.green[600]),
                    ),
                    Text(
                      'Confidence: ${_modelRecommendation['confidence'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.green[600]),
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

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.language, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('🌍 Language Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current language display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Language:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                        ),
                        Text(
                          _translationService.getLanguageDisplayName(_currentLanguage),
                          style: TextStyle(fontSize: 16, color: Colors.blue[600]),
                        ),
                        if (_detectedLanguage != 'en' && _detectedLanguage != _currentLanguage)
                          Text(
                            'Detected: ${_translationService.getLanguageDisplayName(_detectedLanguage)}',
                            style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Language selection
            DropdownButtonFormField<String>(
              value: _currentLanguage,
              decoration: InputDecoration(
                labelText: 'Select Language',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _translationService.getSupportedLanguages().map((langCode) {
                return DropdownMenuItem(
                  value: langCode,
                  child: Text('${_translationService.getLanguageDisplayName(langCode)} ($langCode)'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentLanguage = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Auto-detection info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Language auto-detection is enabled. The app will automatically detect and translate your voice input.',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
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

  @override
  void dispose() {
    _symptomController.dispose();
    _stt.dispose();
    _characterEngine.dispose();
    _usageLogger.close();
    _translationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: 8),
            Text("BeforeDoctor: Voice Assistant"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelectionDialog,
            tooltip: 'Language Settings',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalyticsDialog,
            tooltip: 'Usage Analytics',
          ),
          IconButton(
            icon: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.upload),
            onPressed: _isUploading ? null : _uploadToGoogleSheets,
            tooltip: 'Upload to Google Sheets',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showModelSelectionDialog,
            tooltip: 'Model Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model Selection Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Model:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _selectedModel == 'auto' ? '🔄 Auto-Select' : _selectedModel.toUpperCase(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (_modelRecommendation.isNotEmpty) ...[
                        Text(
                          'Recommended: ${_modelRecommendation['recommendedModel']?.toUpperCase() ?? 'N/A'}',
                          style: TextStyle(fontSize: 12, color: Colors.green[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showModelSelectionDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Input Area
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.child_care, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Symptom Checker',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            'Enter or speak your child\'s symptoms',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _symptomController,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'e.g., fever, cough, vomiting',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _isListening
                      ? const Icon(Icons.mic, color: Colors.red)
                      : null,
                    prefixIcon: const Icon(Icons.edit_note),
                  ),
                  maxLines: 3,
                  enabled: !_isListening,
                ),
                if (_isListening) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mic, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Listening... Tap mic to stop',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons - Enhanced layout
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
                    backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 3,
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
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Symptom Extraction Results
          if (_symptomExtractionResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.medical_services, color: Colors.blue[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔍 Symptom Analysis:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Method: ${_symptomExtractionResult!.methodDescription}',
                              style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                            ),
                            Text(
                              'Confidence: ${_symptomExtractionResult!.confidenceDescription}',
                              style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detected Symptoms: ${_symptomExtractionResult!.symptoms.join(', ')}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Multi-Symptom Analysis Results
          if (_multiSymptomAnalysis != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.analytics, color: Colors.purple[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Multi-Symptom Analysis:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Severity: ${_multiSymptomAnalysis!.severityScore.toStringAsFixed(1)}/10',
                              style: TextStyle(fontSize: 12, color: Colors.purple[600]),
                            ),
                            Text(
                              'Confidence: ${(_multiSymptomAnalysis!.confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 12, color: Colors.purple[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_multiSymptomAnalysis!.potentialConditions.isNotEmpty) ...[
                    Text(
                      'Potential Conditions: ${_multiSymptomAnalysis!.potentialConditions.take(3).map((c) => c.condition.replaceAll('_', ' ')).join(', ')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_multiSymptomAnalysis!.emergencyFlags.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '🚨 Emergency Flags: ${_multiSymptomAnalysis!.emergencyFlags.join(', ')}',
                              style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Treatment Recommendations
          if (_treatmentRecommendation != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.medication, color: Colors.orange[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💊 Treatment Recommendations:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Age Group: ${_treatmentRecommendation!.ageGroup}',
                              style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                            ),
                            Text(
                              'Severity: ${_treatmentRecommendation!.severityScore.toStringAsFixed(1)}/10',
                              style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_treatmentRecommendation!.medications.isNotEmpty) ...[
                    Text(
                      'Medications: ${_treatmentRecommendation!.medications.map((m) => m.name).join(', ')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_treatmentRecommendation!.homeCare.isNotEmpty) ...[
                    Text(
                      'Home Care: ${_treatmentRecommendation!.homeCare.take(3).join(', ')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_treatmentRecommendation!.whenToSeekCare.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.amber[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'When to Seek Care: ${_treatmentRecommendation!.whenToSeekCare.take(2).join(', ')}',
                              style: TextStyle(fontSize: 12, color: Colors.amber[700], fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Voice Recognition Display
          if (_recognizedText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.mic, color: Colors.green[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'You said:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (_stt.confidence > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Confidence: ${(_stt.confidence * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _stt.confidence > 0.8 
                                        ? Colors.green[600] 
                                        : _stt.confidence > 0.6 
                                          ? Colors.orange[600] 
                                          : Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _stt.confidence > 0.8 
                                      ? Icons.check_circle 
                                      : _stt.confidence > 0.6 
                                        ? Icons.warning 
                                        : Icons.error,
                                    size: 16,
                                    color: _stt.confidence > 0.8 
                                      ? Colors.green[600] 
                                      : _stt.confidence > 0.6 
                                        ? Colors.orange[600] 
                                        : Colors.red[600],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_stt.confidence < 0.8 && _recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Low confidence detected. Consider re-recording for better accuracy.',
                              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // AI Response Display
          if (_aiResponse.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.psychology, color: Colors.blue[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🤖 AI Response:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedModel.toUpperCase(),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _aiResponse,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Clear Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _aiResponse = '';
                _recognizedText = '';
                _symptomController.clear();
                _multiSymptomAnalysis = null;
                _symptomExtractionResult = null;
                _treatmentRecommendation = null;
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
} 