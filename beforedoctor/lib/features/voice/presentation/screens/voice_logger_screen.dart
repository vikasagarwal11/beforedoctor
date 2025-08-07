import 'package:flutter/material.dart';
import '../../../../services/stt_service.dart';
import '../../../../core/services/ai_prompt_service.dart';
import '../../../../services/llm_service.dart';
import '../../../../core/services/character_interaction_engine.dart';
import '../../../../services/usage_logger_service.dart';
import '../../../../services/sheet_uploader_example.dart';
import '../../../../services/diseases_symptoms_service.dart';
import '../../../../services/pubmed_dataset_service.dart';
import '../../../../services/disease_prediction_service.dart';
import '../../../../core/services/nih_chest_xray_service.dart';
import '../../../../core/services/enhanced_nih_service.dart';
import '../../../../services/vaccination_coverage_service.dart';
import '../../../../services/ai_enhanced_voice_service.dart';
import '../../../../services/ai_model_service.dart';
import '../../../../core/services/ai_response_orchestrator.dart';
import '../widgets/ai_results_widget.dart';
import 'pubmed_dataset_screen.dart';

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
  final DiseasesSymptomsService _diseasesSymptomsService = DiseasesSymptomsService();
  final PubMedDatasetService _pubmedService = PubMedDatasetService();
  final DiseasePredictionService _diseasePredictionService = DiseasePredictionService();
  final AIResponseOrchestrator _aiOrchestrator = AIResponseOrchestrator();

  String _recognizedText = '';
  String _aiResponse = '';
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isUploading = false;
  String _selectedModel = 'auto';
  Map<String, dynamic> _modelPerformance = {};
  Map<String, dynamic> _modelRecommendation = {};
  Map<String, dynamic> _analytics = {};
  
  // Disease prediction variables
  Map<String, dynamic> _diseasePrediction = {};
  List<String> _similarDiseases = [];
  Map<String, dynamic> _treatmentRecommendations = {};
  bool _showDiseasePrediction = false;
  
  // AI Enhanced variables
  Map<String, dynamic> _aiResults = {};
  bool _showAIResults = false;
  bool _aiModelsLoaded = false;

  // Enhanced child metadata with comprehensive vital information
  final Map<String, String> _childMetadata = {
    'child_name': 'Vihaan',
    'child_age': '4',
    'child_gender': 'male',
    'child_weight_kg': '16.5', // Weight in kg for dosage calculations
    'child_height_cm': '105', // Height in cm for growth tracking
    'child_bmi': '14.9', // BMI for health assessment
    'child_birth_date': '2020-03-15', // For precise age calculations
    'child_blood_type': 'O+', // For emergency situations
    'child_allergies': 'None', // Critical for medication safety
    'child_medications': '', // Current medications
    'child_medical_history': '', // Past conditions
    'child_immunization_status': 'Up to date', // Vaccination status
    'child_developmental_milestones': 'Normal', // Development tracking
    'child_activity_level': 'Moderate', // For health recommendations
    'child_dietary_restrictions': 'None', // For treatment considerations
    'child_emergency_contact': 'Parent: 555-0123', // Emergency info
    'child_pediatrician': 'Dr. Smith', // Primary care provider
    'child_insurance': 'Family Plan', // Insurance information
    'symptom_duration': '2 days',
    'temperature': '',
    'associated_symptoms': '',
    'medications': '',
  };

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// Get comprehensive AI response using orchestrator
  Future<void> _getComprehensiveAIResponse(List<String> symptoms, String? question) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final childContext = {
        'child_age': int.tryParse(_childMetadata['child_age'] ?? '5'),
        'has_chronic_condition': _childMetadata['child_medical_history']?.isNotEmpty == true,
        'recent_illness': false, // Could be enhanced with recent logs
        'immunization_status': _childMetadata['child_immunization_status'] == 'Up to date' ? 'complete' : 'incomplete',
      };

      final response = await _aiOrchestrator.getComprehensiveResponse(
        symptoms: symptoms,
        childContext: childContext,
        userQuestion: question,
      );

      setState(() {
        _aiResponse = response['response'] ?? 'No response available';
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _aiResponse = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Widget _buildDiseaseInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    await _pubmedService.initialize();
    await _diseasesSymptomsService.initialize();
    
    // Initialize AI models
    _aiModelsLoaded = await AIModelService.loadModels();
    
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
    });

    _stt.startListening(
      onResult: (text, detectedLanguage) {
        setState(() {
          _recognizedText = text;
          _symptomController.text = text;
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        _showUserFeedback('Voice recognition error: $error', isError: true);
      },
    );
  }

  void _stopListening() {
    _stt.stopListening();
    setState(() => _isListening = false);
  }

  // Enhanced symptom processing with better error handling
  Future<void> _processSymptom(String symptom) async {
    if (symptom.trim().isEmpty) {
      _showUserFeedback('Please enter a symptom', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _aiResponse = '';
    });

    try {
      // Start character thinking animation
      _characterEngine.startThinking();

      // Build prompt using AIPromptService
      final prompt = await _promptService.buildEnhancedLLMPrompt(symptom, _childMetadata);
      if (prompt.isEmpty) {
        setState(() {
          _aiResponse = 'No template found for "$symptom".';
          _isProcessing = false;
        });
        _showUserFeedback('No template found for this symptom', isError: true);
        return;
      }

      // Call AI service with dynamic model selection
      String llmResponse;
      String modelUsed;
      int latencyMs = 0;
      double score = 0.0;

      final startTime = DateTime.now();
      
      switch (_selectedModel) {
        case 'auto':
          llmResponse = await _llmService.getAIResponseSimple(prompt);
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

      // Get PubMed treatment recommendations
      final pubmedRecommendations = _pubmedService.getTreatmentRecommendations(symptom, _childMetadata);
      
      // Get Diseases_Symptoms analysis
      final diseasesAnalysis = await _diseasesSymptomsService.analyzeSymptoms(symptom);
      
      // React to symptom and speak the result
      _characterEngine.reactToSymptom(symptom);
      await _characterEngine.speakWithAnimation(llmResponse);
      
      // Add PubMed insights to response if available
      if (pubmedRecommendations['studies_found'] > 0) {
        final pubmedInsights = '\n\n🔬 PubMed Research Insights:\n'
            '• Found ${pubmedRecommendations['studies_found']} relevant studies\n'
            '• Evidence Level: ${pubmedRecommendations['evidence_level']}\n'
            '• Common Treatments: ${(pubmedRecommendations['treatments'] as List).take(3).join(', ')}\n'
            '• Age Considerations: ${(pubmedRecommendations['age_considerations'] as List).take(2).join(', ')}';
        
        llmResponse += pubmedInsights;
      }
      
      // Add Diseases_Symptoms insights
      if (diseasesAnalysis['symptoms'].isNotEmpty) {
        final diseasesInsights = '\n\n🏥 AI Disease Analysis:\n'
            '• Detected Symptoms: ${(diseasesAnalysis['symptoms'] as List).join(', ')}\n'
            '• Urgency Level: ${diseasesAnalysis['urgency_level'].toString().toUpperCase()}\n';
        
        if (diseasesAnalysis['emergency_symptoms'].isNotEmpty) {
          diseasesInsights += '• ⚠️ EMERGENCY SYMPTOMS: ${(diseasesAnalysis['emergency_symptoms'] as List).join(', ')}\n';
        }
        
        if (diseasesAnalysis['recommendations']['treatment'] != null) {
          final treatment = diseasesAnalysis['recommendations']['treatment'];
          diseasesInsights += '• Recommended Treatment: ${treatment['treatment']}\n';
        }
        
        llmResponse += diseasesInsights;
      }

      // Add Disease Database prediction
      try {
        final diseasePrediction = await _diseasePredictionService.predictDisease(symptom);
        final similarDiseases = await _diseasePredictionService.getSimilarDiseases(symptom);
        final treatmentRecommendations = await _diseasePredictionService.getTreatmentRecommendations(
          diseasePrediction['disease'] ?? 'Unknown'
        );
        
        // Process with AI enhancement
        if (_aiModelsLoaded) {
          final aiResults = await AIEnhancedVoiceService.processVoiceWithAI(symptom);
          setState(() {
            _aiResults = aiResults;
            _showAIResults = true;
          });
        }
        
        setState(() {
          _diseasePrediction = diseasePrediction;
          _similarDiseases = similarDiseases;
          _treatmentRecommendations = treatmentRecommendations;
          _showDiseasePrediction = true;
        });
        
        if (diseasePrediction['disease'] != null && diseasePrediction['disease'] != 'Predicted Disease') {
          final diseaseInsights = '\n\n🏥 Disease Database Analysis:\n'
              '• Predicted Disease: ${diseasePrediction['disease']}\n'
              '• Confidence: ${(diseasePrediction['confidence'] * 100).toStringAsFixed(1)}%\n'
              '• Similar Conditions: ${similarDiseases.take(3).join(', ')}\n';
          
          if (treatmentRecommendations['treatments'] != null) {
            diseaseInsights += '• Recommended Treatments: ${(treatmentRecommendations['treatments'] as List).take(3).join(', ')}\n';
          }
          
          llmResponse += diseaseInsights;
        }
      } catch (e) {
        // Disease prediction failed, continue without it
        print('Disease prediction error: $e');
      }

      // Add Enhanced NIH Chest X-ray respiratory analysis
      try {
        final childAge = int.tryParse(_childMetadata['child_age'] ?? '4') ?? 4;
        final childGender = _childMetadata['child_gender'] ?? 'M';
        
        if (EnhancedNIHService.hasRespiratorySymptoms(symptom)) {
          final enhancedAnalysis = EnhancedNIHService.analyzeRespiratorySymptoms(symptom, childAge, childGender: childGender);
          
          if (enhancedAnalysis['error'] == null) {
            final enhancedInsights = '\n\n🫁 Enhanced NIH Respiratory Analysis:\n'
                '• Detected Conditions: ${(enhancedAnalysis['symptoms'] as List).join(', ')}\n'
                '• Severity Level: ${enhancedAnalysis['severity'].toString().toUpperCase()}\n'
                '• Urgency Level: ${enhancedAnalysis['urgency'].toString().toUpperCase()}\n'
                '• Dataset Accuracy: ${(enhancedAnalysis['dataset_accuracy'] * 100).toStringAsFixed(0)}%\n'
                '• Documentation Based: ${enhancedAnalysis['documentation_based'] ? 'Yes' : 'No'}\n';
            
            if (enhancedAnalysis['recommendations'] != null) {
              final recommendations = enhancedAnalysis['recommendations'] as List;
              enhancedInsights += '• Enhanced Recommendations: ${recommendations.take(3).join(', ')}\n';
            }
            
            llmResponse += enhancedInsights;
          }
        }
      } catch (e) {
        // Enhanced NIH analysis failed, continue without it
        print('Enhanced NIH Chest X-ray analysis error: $e');
      }

      // Add Vaccination Coverage Analysis
      try {
        final vaccinationAnalysis = VaccinationCoverageService.extractVaccinationFromVoice(symptom);
        
        if (vaccinationAnalysis['is_vaccination'] == true) {
          final childAge = int.tryParse(_childMetadata['child_age'] ?? '4') ?? 4;
          final childId = _childMetadata['child_name'] ?? 'Unknown';
          
          // Check if CDC Enhanced tracking is enabled
          final isEnhancedTracking = _childMetadata['child_immunization_status'] == 'CDC Enhanced';
          
          // Mock vaccination history - in real app, this would come from database
          final vaccinationHistory = <String, List<Map<String, dynamic>>>{};
          
          final vaccinationStatus = VaccinationCoverageService.checkVaccinationStatus(
            childId: childId,
            ageInMonths: childAge * 12, // Convert years to months
            vaccinationHistory: vaccinationHistory,
          );
          
          if (vaccinationStatus['status'] == 'success') {
            final vaccinationInsights = '\n\n💉 Vaccination Analysis:\n'
                '• Detected Vaccine: ${vaccinationAnalysis['detected_vaccine']}\n'
                '• Coverage Status: ${vaccinationStatus['coverage_percentage'].toStringAsFixed(1)}% complete\n'
                '• Missing Vaccines: ${vaccinationStatus['missing_vaccines'].length}\n'
                '• Completed Vaccines: ${vaccinationStatus['completed_vaccines'].length}\n';
            
            if (isEnhancedTracking) {
              vaccinationInsights += '• 🎯 CDC Enhanced Tracking: Active\n';
            } else {
              vaccinationInsights += '• ℹ️ Basic tracking: Enable "CDC Enhanced" for detailed vaccine tracking\n';
            }
            
            if (vaccinationStatus['recommendations'].isNotEmpty) {
              vaccinationInsights += '• Recommendations: ${(vaccinationStatus['recommendations'] as List).take(3).join(', ')}\n';
            }
            
            llmResponse += vaccinationInsights;
            
            // Log vaccination event if detected
            if (vaccinationAnalysis['detected_vaccine'] != null) {
              final vaccinationRecord = VaccinationCoverageService.logVaccination(
                childId: childId,
                vaccineName: vaccinationAnalysis['detected_vaccine'],
                vaccinationDate: DateTime.now(),
                notes: 'Logged via voice command: $symptom',
              );
              
              if (vaccinationRecord['status'] == 'success') {
                print('Vaccination logged successfully: ${vaccinationRecord['record']}');
              }
            }
          }
        }
      } catch (e) {
        // Vaccination analysis failed, continue without it
        print('Vaccination analysis error: $e');
      }

      // Log the interaction using UsageLoggerService
      await _usageLogger.logInteraction(
        symptom: symptom,
        promptUsed: prompt,
        modelUsed: modelUsed,
        aiResponse: llmResponse,
        latencyMs: latencyMs,
        success: llmResponse.isNotEmpty,
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
        _aiResponse = llmResponse;
        _isProcessing = false;
      });

      // Show success message
      _showUserFeedback('✅ AI Response ready!', isError: false);

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
            Flexible(
              child: const Text(
                '📊 Usage Analytics',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
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
            Flexible(
              child: const Text(
                '🔧 Model Selection',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: InputDecoration(
                  labelText: 'Select AI Model',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('🔄 Auto-Select', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'openai', child: Text('OpenAI GPT-4o', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'grok', child: Text('xAI Grok', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'fallback', child: Text('Local Fallback', overflow: TextOverflow.ellipsis)),
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
                        Expanded(
                          child: Text(
                            '💡 AI Recommendation:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    )
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
    ),
  );

  void _showChildInformationDialog() {
    final _nameController = TextEditingController(text: _childMetadata['child_name']);
    final _ageController = TextEditingController(text: _childMetadata['child_age']);
    final _weightController = TextEditingController(text: _childMetadata['child_weight_kg']);
    final _heightController = TextEditingController(text: _childMetadata['child_height_cm']);
    final _birthDateController = TextEditingController(text: _childMetadata['child_birth_date']);
    final _bloodTypeController = TextEditingController(text: _childMetadata['child_blood_type']);
    final _allergiesController = TextEditingController(text: _childMetadata['child_allergies']);
    final _medicationsController = TextEditingController(text: _childMetadata['child_medications']);
    final _medicalHistoryController = TextEditingController(text: _childMetadata['child_medical_history']);
    final _emergencyContactController = TextEditingController(text: _childMetadata['child_emergency_contact']);
    final _pediatricianController = TextEditingController(text: _childMetadata['child_pediatrician']);
    
    String _selectedGender = _childMetadata['child_gender'] ?? 'male';
    String _selectedImmunizationStatus = _childMetadata['child_immunization_status'] ?? 'Up to date';
    String _selectedDevelopmentalStatus = _childMetadata['child_developmental_milestones'] ?? 'Normal';
    String _selectedActivityLevel = _childMetadata['child_activity_level'] ?? 'Moderate';
    String _selectedDietaryRestrictions = _childMetadata['child_dietary_restrictions'] ?? 'None';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.child_care, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                '👶 Child Health Profile',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('Basic Information'),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Child Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: 'Age (years)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) => _selectedGender = value ?? 'male',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Birth Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),
              
              // Vital Measurements
              _buildSectionTitle('Vital Measurements'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bloodTypeController,
                decoration: InputDecoration(
                  labelText: 'Blood Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),

              // Medical Information
              _buildSectionTitle('Medical Information'),
              TextField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., Penicillin, Peanuts, Latex',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _medicationsController,
                decoration: InputDecoration(
                  labelText: 'Current Medications',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., Albuterol inhaler, Daily vitamins',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _medicalHistoryController,
                decoration: InputDecoration(
                  labelText: 'Medical History',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., Asthma, Previous surgeries',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedImmunizationStatus,
                decoration: InputDecoration(
                  labelText: 'Immunization Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Enhanced with CDC vaccination tracking',
                ),
                items: const [
                  DropdownMenuItem(value: 'Up to date', child: Text('✅ Up to date')),
                  DropdownMenuItem(value: 'Partially vaccinated', child: Text('⚠️ Partially vaccinated')),
                  DropdownMenuItem(value: 'Behind schedule', child: Text('🚨 Behind schedule')),
                  DropdownMenuItem(value: 'Unknown', child: Text('❓ Unknown')),
                  DropdownMenuItem(value: 'CDC Enhanced', child: Text('💉 CDC Enhanced Tracking')),
                ],
                onChanged: (value) => _selectedImmunizationStatus = value ?? 'Up to date',
              ),
              const SizedBox(height: 8),
              // Add vaccination coverage info if CDC Enhanced is selected
              if (_selectedImmunizationStatus == 'CDC Enhanced')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vaccines, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CDC Vaccination Coverage Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Voice commands will now detect and track specific vaccines:\n'
                        '• "Log flu shot for Vihaan"\n'
                        '• "Check vaccination status"\n'
                        '• "What vaccines are missing?"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDevelopmentalStatus,
                decoration: InputDecoration(
                  labelText: 'Developmental Milestones',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Slightly delayed', child: Text('Slightly delayed')),
                  DropdownMenuItem(value: 'Significantly delayed', child: Text('Significantly delayed')),
                  DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                ],
                onChanged: (value) => _selectedDevelopmentalStatus = value ?? 'Normal',
              ),

              const SizedBox(height: 20),

              // Lifestyle Information
              _buildSectionTitle('Lifestyle Information'),
              DropdownButtonFormField<String>(
                value: _selectedActivityLevel,
                decoration: InputDecoration(
                  labelText: 'Activity Level',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Very high', child: Text('Very high')),
                ],
                onChanged: (value) => _selectedActivityLevel = value ?? 'Moderate',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDietaryRestrictions,
                decoration: InputDecoration(
                  labelText: 'Dietary Restrictions',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'None', child: Text('None')),
                  DropdownMenuItem(value: 'Vegetarian', child: Text('Vegetarian')),
                  DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
                  DropdownMenuItem(value: 'Gluten-free', child: Text('Gluten-free')),
                  DropdownMenuItem(value: 'Dairy-free', child: Text('Dairy-free')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => _selectedDietaryRestrictions = value ?? 'None',
              ),

              const SizedBox(height: 20),

              // Emergency Information
              _buildSectionTitle('Emergency Information'),
              TextField(
                controller: _emergencyContactController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., Parent: 555-0123',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pediatricianController,
                decoration: InputDecoration(
                  labelText: 'Primary Pediatrician',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., Dr. Smith - Pediatrics',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Calculate BMI if weight and height are provided
              String bmi = '';
              if (_weightController.text.isNotEmpty && _heightController.text.isNotEmpty) {
                try {
                  double weight = double.parse(_weightController.text);
                  double height = double.parse(_heightController.text) / 100; // Convert cm to meters
                  double bmiValue = weight / (height * height);
                  bmi = bmiValue.toStringAsFixed(1);
                } catch (e) {
                  bmi = '';
                }
              }

              setState(() {
                _childMetadata['child_name'] = _nameController.text;
                _childMetadata['child_age'] = _ageController.text;
                _childMetadata['child_gender'] = _selectedGender;
                _childMetadata['child_weight_kg'] = _weightController.text;
                _childMetadata['child_height_cm'] = _heightController.text;
                _childMetadata['child_bmi'] = bmi;
                _childMetadata['child_birth_date'] = _birthDateController.text;
                _childMetadata['child_blood_type'] = _bloodTypeController.text;
                _childMetadata['child_allergies'] = _allergiesController.text;
                _childMetadata['child_medications'] = _medicationsController.text;
                _childMetadata['child_medical_history'] = _medicalHistoryController.text;
                _childMetadata['child_immunization_status'] = _selectedImmunizationStatus;
                _childMetadata['child_developmental_milestones'] = _selectedDevelopmentalStatus;
                _childMetadata['child_activity_level'] = _selectedActivityLevel;
                _childMetadata['child_dietary_restrictions'] = _selectedDietaryRestrictions;
                _childMetadata['child_emergency_contact'] = _emergencyContactController.text;
                _childMetadata['child_pediatrician'] = _pediatricianController.text;
              });
              Navigator.of(context).pop();
              _showUserFeedback('✅ Child information updated!', isError: false);
            },
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
    _pubmedService.dispose();
    _diseasesSymptomsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                "BeforeDoctor: Voice Assistant",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.child_care),
            onPressed: _showChildInformationDialog,
            tooltip: 'Child Information',
          ),
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PubMedDatasetScreen()),
            ),
            tooltip: 'PubMed Dataset',
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
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton.icon(
                    onPressed: _showModelSelectionDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Child Information Display
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
                      child: Icon(Icons.child_care, color: Colors.orange[600]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_childMetadata['child_name']} (${_childMetadata['child_age']} years, ${_childMetadata['child_gender']})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (_childMetadata['child_weight_kg']?.isNotEmpty == true && 
                              _childMetadata['child_height_cm']?.isNotEmpty == true) ...[
                            Text(
                              '${_childMetadata['child_weight_kg']} kg, ${_childMetadata['child_height_cm']} cm',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            if (_childMetadata['child_bmi']?.isNotEmpty == true) ...[
                              Text(
                                'BMI: ${_childMetadata['child_bmi']}',
                                style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                              ),
                            ],
                          ],
                          if (_childMetadata['child_allergies']?.isNotEmpty == true && 
                              _childMetadata['child_allergies'] != 'None') ...[
                            Text(
                              '⚠️ Allergies: ${_childMetadata['child_allergies']}',
                              style: TextStyle(fontSize: 12, color: Colors.red[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _showChildInformationDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
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
                      const Text(
                        'You said:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: const TextStyle(fontSize: 16),
                  ),
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
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedModel.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
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

          // Disease Prediction Display
          if (_showDiseasePrediction && _diseasePrediction.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
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
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.medical_services, color: Colors.green[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🏥 Disease Database Analysis:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
          // AI Results Display
          if (_showAIResults && _aiResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            AIResultsWidget(
              aiResults: _aiResults,
              onTreatmentTap: () {
                // Handle treatment tap
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Treatment recommendations: ${_aiResults['ai_insights']['urgency'] ?? 'Consult healthcare provider'}')),
                );
              },
              onRiskTap: () {
                // Handle risk tap
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Risk level: ${_aiResults['risk_level']?.toString().toUpperCase() ?? 'MEDIUM'}')),
                );
              },
            ),
          ],
                  const SizedBox(height: 12),
                  if (_diseasePrediction['disease'] != null) ...[
                    _buildDiseaseInfoRow('Predicted Disease', _diseasePrediction['disease']),
                    if (_diseasePrediction['confidence'] != null)
                      _buildDiseaseInfoRow('Confidence', '${(_diseasePrediction['confidence'] * 100).toStringAsFixed(1)}%'),
                  ],
                  if (_similarDiseases.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDiseaseInfoRow('Similar Conditions', _similarDiseases.take(3).join(', ')),
                  ],
                  if (_treatmentRecommendations['treatments'] != null) ...[
                    const SizedBox(height: 8),
                    _buildDiseaseInfoRow('Recommended Treatments', 
                      (_treatmentRecommendations['treatments'] as List).take(3).join(', ')),
                  ],
                  if (_treatmentRecommendations['medications'] != null) ...[
                    const SizedBox(height: 8),
                    _buildDiseaseInfoRow('Medications', 
                      (_treatmentRecommendations['medications'] as List).take(2).join(', ')),
                  ],
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
                _diseasePrediction = {};
                _similarDiseases = [];
                _treatmentRecommendations = {};
                _showDiseasePrediction = false;
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