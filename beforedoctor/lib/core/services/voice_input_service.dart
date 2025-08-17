import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class VoiceInputService {
  static VoiceInputService? _instance;
  static VoiceInputService get instance => _instance ??= VoiceInputService._internal();

  VoiceInputService._internal();

  // Speech to Text (temporarily disabled due to compatibility issues)
  // final stt.SpeechToText _speechToText = stt.SpeechToText();
  
  // Configuration
  final AppConfig _config = AppConfig.instance;
  
  // State management
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastTranscription = '';
  double _confidence = 0.0;
  
  // Stream controllers for real-time updates
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  final StreamController<double> _confidenceController = StreamController<double>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  final StreamController<bool> _processingController = StreamController<bool>.broadcast();

  // Streams for UI updates
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<double> get confidenceStream => _confidenceController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<bool> get processingStream => _processingController.stream;

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get lastTranscription => _lastTranscription;
  double get confidence => _confidence;

  /// Initialize the voice service (simplified version)
  Future<bool> initialize() async {
    try {
      // For now, we'll use text input as fallback
      // TODO: Re-enable speech_to_text when compatibility issues are resolved
      print('✅ Voice input service initialized (text input mode)');
      return true;
    } catch (e) {
      print('❌ Error initializing voice service: $e');
      return false;
    }
  }

  /// Simulate voice input with text (temporary solution)
  Future<void> simulateVoiceInput(String text) async {
    if (_isListening || _isProcessing) return;

    try {
      _isListening = true;
      _listeningController.add(true);
      _transcriptionController.add('');
      _confidenceController.add(0.0);

      // Simulate listening delay
      await Future.delayed(const Duration(seconds: 1));

      // Simulate transcription
      _lastTranscription = text;
      _confidence = 0.95; // High confidence for text input
      
      _transcriptionController.add(_lastTranscription);
      _confidenceController.add(_confidence);
      
      print('🎯 Simulated transcription: $_lastTranscription (confidence: $_confidence)');
      
      // Process the transcription for symptom detection
      _processTranscription(_lastTranscription);
      
    } catch (e) {
      print('❌ Error simulating voice input: $e');
      _isListening = false;
      _listeningController.add(false);
    }
  }

  /// Start listening for voice input (placeholder for future speech integration)
  Future<void> startListening({
    String? languageCode,
    Duration? listenDuration,
  }) async {
    if (_isListening || _isProcessing) return;

    try {
      _isListening = true;
      _listeningController.add(true);
      _transcriptionController.add('');
      _confidenceController.add(0.0);

      // TODO: Re-enable speech_to_text when compatibility issues are resolved
      print('🎤 Voice listening not available - use simulateVoiceInput() for testing');

    } catch (e) {
      print('❌ Error starting voice listening: $e');
      _isListening = false;
      _listeningController.add(false);
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      _listeningController.add(false);
      print('🛑 Stopped listening');
    } catch (e) {
      print('❌ Error stopping voice listening: $e');
    }
  }

  /// Handle speech recognition results (placeholder)
  void _onSpeechResult(dynamic result) {
    // TODO: Re-enable when speech_to_text is working
    print('Speech recognition not available');
  }

  /// Process transcription for symptom detection
  void _processTranscription(String transcription) {
    if (transcription.isEmpty) return;

    _isProcessing = true;
    _processingController.add(true);

    // AI-FIRST APPROACH: Send directly to AI for real-time processing
    // No more rule-based keyword matching - let AI handle everything
    _processWithAI(transcription);
  }

  /// Process voice input directly with AI (primary method)
  Future<void> _processWithAI(String transcription) async {
    try {
      print('🧠 Processing with AI: "$transcription"');
      
      // Step 1: Send directly to AI for comprehensive analysis
      final aiResult = await _enhanceSymptomExtraction(transcription, []);
      
      if (aiResult.isNotEmpty) {
        print('✅ AI processing successful: $aiResult');
        
        // Step 2: AI has already extracted symptoms, severity, and context
        // No need for manual keyword matching
        final symptoms = aiResult['symptoms'] ?? [];
        final enhancedData = aiResult['enhanced_extraction'] ?? '';
        final apiUsed = aiResult['api_used'] ?? 'unknown';
        
        print('🏥 AI extracted symptoms: $symptoms');
        print('📝 AI analysis: $enhancedData');
        print('🔌 API used: $apiUsed');
        
        // Step 3: Trigger AI response generation
        _onSymptomsDetected(aiResult, transcription);
        
      } else {
        print('❌ AI processing failed, falling back to basic detection');
        // Only fallback to rules if AI completely fails
        _fallbackToRules(transcription);
      }
      
    } catch (e) {
      print('❌ Error in AI processing: $e');
      _fallbackToRules(transcription);
    } finally {
      _isProcessing = false;
      _processingController.add(false);
    }
  }

  /// Fallback to rule-based detection (only if AI fails)
  void _fallbackToRules(String transcription) {
    print('🔄 Falling back to rule-based detection');
    
    // Detect symptoms from transcription using keyword matching
    final symptoms = detectSymptoms(transcription);
    
    if (symptoms.isNotEmpty) {
      print('🏥 Rule-based symptoms detected: $symptoms');
      // Create basic result structure
      final fallbackResult = {
        'symptoms': symptoms,
        'transcription': transcription,
        'enhanced_extraction': 'Basic rule-based detection',
        'api_used': 'fallback_rules',
      };
      _onSymptomsDetected(fallbackResult, transcription);
    } else {
      print('❓ No symptoms detected even with rules');
      _isProcessing = false;
      _processingController.add(false);
    }
  }

  /// Detect symptoms from transcription using keyword matching
  List<String> detectSymptoms(String transcription) {
    final lowerTranscription = transcription.toLowerCase();
    final symptoms = <String>[];

    // Symptom keywords mapping
    final symptomKeywords = {
      'fever': ['fever', 'temperature', 'hot', 'burning up', 'temp'],
      'cough': ['cough', 'coughing', 'hack', 'chest'],
      'vomiting': ['vomit', 'throw up', 'sick', 'nausea', 'puke'],
      'diarrhea': ['diarrhea', 'loose stool', 'runny', 'stomach'],
      'ear_pain': ['ear pain', 'earache', 'ear hurts', 'pulling ear'],
      'rash': ['rash', 'spots', 'bumps', 'red skin', 'itchy'],
      'headache': ['headache', 'head hurts', 'migraine', 'head pain'],
      'sore_throat': ['sore throat', 'throat hurts', 'swallowing'],
      'breathing_difficulty': ['breathing', 'wheezing', 'shortness', 'chest tight'],
      'back_pain': ['back pain', 'back hurts', 'backache', 'back sore', 'spine', 'lower back'],
      'general_pain': ['pain', 'hurts', 'ache', 'sore', 'hurt', 'aching', 'painful'],
      'stomach_pain': ['stomach pain', 'belly ache', 'tummy hurts', 'abdominal pain', 'cramps'],
      'joint_pain': ['joint pain', 'knee hurts', 'elbow pain', 'ankle pain', 'wrist pain'],
      'muscle_pain': ['muscle pain', 'muscle ache', 'sore muscles', 'body aches'],
      'fatigue': ['tired', 'fatigue', 'exhausted', 'weak', 'lethargic', 'no energy'],
      'loss_of_appetite': ['no appetite', 'not hungry', 'won\'t eat', 'refusing food'],
      'sleep_issues': ['can\'t sleep', 'insomnia', 'sleeping too much', 'restless sleep'],
    };

    for (final entry in symptomKeywords.entries) {
      final symptom = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (lowerTranscription.contains(keyword)) {
          symptoms.add(symptom);
          break;
        }
      }
    }

    return symptoms;
  }

  /// Enhance symptom extraction using AI
  Future<Map<String, dynamic>> _enhanceSymptomExtraction(String transcription, List<String> symptoms) async {
    try {
      // AI-FIRST: Send raw voice input directly to AI for comprehensive analysis
      // No pre-detected symptoms needed - let AI figure everything out
      
      final primaryApi = _config.primaryVoiceApi;
      final fallbackApi = _config.fallbackVoiceApi;
      
      Map<String, dynamic> result = {};
      
      if (primaryApi == 'grok') {
        result = await _callGrokAPI(transcription);
      } else if (primaryApi == 'openai') {
        result = await _callOpenAIAPI(transcription);
      }
      
      // If primary fails and fallback is enabled, try fallback
      if (result.isEmpty && _config.autoFallbackEnabled) {
        if (fallbackApi == 'grok') {
          result = await _callGrokAPI(transcription);
        } else if (fallbackApi == 'openai') {
          result = await _callOpenAIAPI(transcription);
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Error enhancing symptom extraction: $e');
      return {'symptoms': symptoms, 'transcription': transcription};
    }
  }

  /// Call xAI Grok Voice API
  Future<Map<String, dynamic>> _callGrokAPI(String transcription) async {
    try {
      //final url = Uri.parse('https://api.x.ai/v1/chat/completions');
      final url = Uri.parse(_config.xaiGrokApiEndpoint);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.xaiGrokApiKey}',
        },
        body: jsonEncode({
          //'model': 'grok-beta',
          'model': _config.xaiGrokModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are Dr. Healthie, a pediatric AI assistant. Analyze voice input and provide:

1. SYMPTOM EXTRACTION: Identify all symptoms, severity, and context
2. MEDICAL ASSESSMENT: Basic risk level and urgency
3. FOLLOW-UP QUESTIONS: 3-5 relevant medical questions to gather more information
4. IMMEDIATE ADVICE: What to do right now
5. WHEN TO SEEK CARE: Clear guidance on medical attention

Format your response as JSON with these fields:
{
  "symptoms": ["symptom1", "symptom2"],
  "severity": "low/medium/high",
  "risk_level": "low/medium/high",
  "assessment": "Brief medical assessment",
  "follow_up_questions": ["Question 1?", "Question 2?", "Question 3?"],
  "immediate_advice": "What to do now",
  "seek_care_when": "When to see a doctor",
  "confidence": 0.95
}'''
            },
            {
              'role': 'user',
              'content': 'Analyze this pediatric voice input: "$transcription"'
            }
          ],
          'max_tokens': 800,
          //'temperature': 0.3,
          'temperature': _config.xaiGrokTemperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Try to parse JSON response from AI
        try {
          final aiResponse = jsonDecode(content);
          return {
            'symptoms': aiResponse['symptoms'] ?? [],
            'transcription': transcription,
            'enhanced_extraction': aiResponse,
            'api_used': 'grok',
            'severity': aiResponse['severity'],
            'risk_level': aiResponse['risk_level'],
            'follow_up_questions': aiResponse['follow_up_questions'] ?? [],
            'immediate_advice': aiResponse['immediate_advice'],
            'seek_care_when': aiResponse['seek_care_when'],
          };
        } catch (parseError) {
          // If AI didn't return JSON, treat as text
          return {
            'symptoms': [], // Will be extracted by fallback
            'transcription': transcription,
            'enhanced_extraction': content,
            'api_used': 'grok',
          };
        }
      } else {
        print('❌ Grok API error: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ Error calling Grok API: $e');
      return {};
    }
  }

  /// Call OpenAI Realtime Audio API
  Future<Map<String, dynamic>> _callOpenAIAPI(String transcription) async {
    try {
      //final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final url = Uri.parse(_config.openaiApiEndpoint);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.openaiApiKey}',
        },
        body: jsonEncode({
          //'model': 'gpt-4o',
          'model': _config.openaiModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are Dr. Healthie, a pediatric AI assistant. Analyze voice input and provide:

1. SYMPTOM EXTRACTION: Identify all symptoms, severity, and context
2. MEDICAL ASSESSMENT: Basic risk level and urgency
3. FOLLOW-UP QUESTIONS: 3-5 relevant medical questions to gather more information
4. IMMEDIATE ADVICE: What to do right now
5. WHEN TO SEEK CARE: Clear guidance on medical attention

Format your response as JSON with these fields:
{
  "symptoms": ["symptom1", "symptom2"],
  "severity": "low/medium/high",
  "risk_level": "low/medium/high",
  "assessment": "Brief medical assessment",
  "follow_up_questions": ["Question 1?", "Question 2?", "Question 3?"],
  "immediate_advice": "What to do now",
  "seek_care_when": "When to see a doctor",
  "confidence": 0.95
}'''
            },
            {
              'role': 'user',
              'content': 'Analyze this pediatric voice input: "$transcription"'
            }
          ],
          'max_tokens': 800,
          // 'temperature': 0.3,
          'temperature': _config.openaiTemperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Try to parse JSON response from AI
        try {
          final aiResponse = jsonDecode(content);
          return {
            'symptoms': aiResponse['symptoms'] ?? [],
            'transcription': transcription,
            'enhanced_extraction': aiResponse,
            'api_used': 'openai',
            'severity': aiResponse['severity'],
            'risk_level': aiResponse['risk_level'],
            'follow_up_questions': aiResponse['follow_up_questions'] ?? [],
            'immediate_advice': aiResponse['immediate_advice'],
            'seek_care_when': aiResponse['seek_care_when'],
          };
        } catch (parseError) {
          // If AI didn't return JSON, treat as text
          return {
            'symptoms': [], // Will be extracted by fallback
            'transcription': transcription,
            'enhanced_extraction': content,
            'api_used': 'openai',
          };
        }
      } else {
        print('❌ OpenAI API error: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ Error calling OpenAI API: $e');
      return {};
    }
  }

  /// Callback for when symptoms are detected
  void _onSymptomsDetected(Map<String, dynamic> symptomsData, String transcription) {
    // Enhanced callback with comprehensive AI analysis
    print('🏥 AI Analysis Complete:');
    print('   📝 Transcription: $transcription');
    print('   🏥 Symptoms: ${symptomsData['symptoms']}');
    print('   ⚠️ Severity: ${symptomsData['severity'] ?? 'unknown'}');
    print('   🚨 Risk Level: ${symptomsData['risk_level'] ?? 'unknown'}');
    print('   💡 Assessment: ${symptomsData['assessment'] ?? 'No assessment'}');
    print('   ❓ Follow-up Questions: ${symptomsData['follow_up_questions'] ?? []}');
    print('   🚑 Immediate Advice: ${symptomsData['immediate_advice'] ?? 'No advice'}');
    print('   🏥 Seek Care When: ${symptomsData['seek_care_when'] ?? 'No guidance'}');
    print('   🔌 API Used: ${symptomsData['api_used'] ?? 'unknown'}');
    
    // This will be handled by the UI layer for conversation updates
    print('🏥 Comprehensive AI analysis ready for UI processing');
  }

  /// Get available languages for speech recognition (placeholder)
  List<String> getAvailableLanguages() {
    return ['en_US']; // Default for now
  }

  /// Check if speech recognition is available (placeholder)
  bool get isAvailable => true; // Always true for text input mode

  /// Get current listening status
  bool get isCurrentlyListening => _isListening;

  /// Dispose resources
  void dispose() {
    // _speechToText.cancel(); // Disabled
    _transcriptionController.close();
    _confidenceController.close();
    _listeningController.close();
    _processingController.close();
  }
}

// Example usage:
// final voiceService = VoiceInputService.instance;
// await voiceService.initialize();
// await voiceService.simulateVoiceInput("My child has a fever of 102 degrees");
// voiceService.transcriptionStream.listen((transcription) {
//   print('Transcription: $transcription');
// }); 