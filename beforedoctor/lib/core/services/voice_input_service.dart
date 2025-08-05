import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
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

    // Detect symptoms from transcription
    final symptoms = detectSymptoms(transcription);
    
    if (symptoms.isNotEmpty) {
      print('🏥 Detected symptoms: $symptoms');
      // Trigger symptom processing
      _processSymptoms(symptoms, transcription);
    } else {
      print('❓ No symptoms detected in transcription');
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

  /// Process detected symptoms
  Future<void> _processSymptoms(List<String> symptoms, String transcription) async {
    try {
      // Use AI to enhance symptom extraction
      final enhancedSymptoms = await _enhanceSymptomExtraction(transcription, symptoms);
      
      // Trigger callback or event for symptom processing
      _onSymptomsDetected(enhancedSymptoms, transcription);
      
    } catch (e) {
      print('❌ Error processing symptoms: $e');
    } finally {
      _isProcessing = false;
      _processingController.add(false);
    }
  }

  /// Enhance symptom extraction using AI
  Future<Map<String, dynamic>> _enhanceSymptomExtraction(String transcription, List<String> symptoms) async {
    try {
      // Try xAI Grok first, fallback to OpenAI
      final primaryApi = _config.primaryVoiceApi;
      final fallbackApi = _config.fallbackVoiceApi;
      
      Map<String, dynamic> result = {};
      
      if (primaryApi == 'grok') {
        result = await _callGrokAPI(transcription, symptoms);
      } else if (primaryApi == 'openai') {
        result = await _callOpenAIAPI(transcription, symptoms);
      }
      
      // If primary fails and fallback is enabled, try fallback
      if (result.isEmpty && _config.autoFallbackEnabled) {
        if (fallbackApi == 'grok') {
          result = await _callGrokAPI(transcription, symptoms);
        } else if (fallbackApi == 'openai') {
          result = await _callOpenAIAPI(transcription, symptoms);
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Error enhancing symptom extraction: $e');
      return {'symptoms': symptoms, 'transcription': transcription};
    }
  }

  /// Call xAI Grok Voice API
  Future<Map<String, dynamic>> _callGrokAPI(String transcription, List<String> symptoms) async {
    try {
      final url = Uri.parse('https://api.x.ai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.xaiGrokApiKey}',
        },
        body: jsonEncode({
          'model': 'grok-beta',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a pediatric symptom extraction assistant. Extract symptoms, severity, and additional details from the parent\'s voice input.'
            },
            {
              'role': 'user',
              'content': 'Extract pediatric symptoms from this voice input: "$transcription". Detected symptoms: $symptoms'
            }
          ],
          'max_tokens': 500,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        return {
          'symptoms': symptoms,
          'transcription': transcription,
          'enhanced_extraction': content,
          'api_used': 'grok',
        };
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
  Future<Map<String, dynamic>> _callOpenAIAPI(String transcription, List<String> symptoms) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.openaiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a pediatric symptom extraction assistant. Extract symptoms, severity, and additional details from the parent\'s voice input.'
            },
            {
              'role': 'user',
              'content': 'Extract pediatric symptoms from this voice input: "$transcription". Detected symptoms: $symptoms'
            }
          ],
          'max_tokens': 500,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        return {
          'symptoms': symptoms,
          'transcription': transcription,
          'enhanced_extraction': content,
          'api_used': 'openai',
        };
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
    // This will be handled by the UI layer
    print('🏥 Symptoms detected: $symptomsData');
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