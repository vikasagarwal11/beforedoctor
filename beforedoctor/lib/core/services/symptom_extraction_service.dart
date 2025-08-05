import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SymptomExtractionService {
  static SymptomExtractionService? _instance;
  static SymptomExtractionService get instance => _instance ??= SymptomExtractionService._internal();

  SymptomExtractionService._internal();

  final AppConfig _config = AppConfig.instance;

  /// Extract detailed symptom information from voice input
  Future<Map<String, dynamic>> extractSymptoms(String transcription) async {
    try {
      // Basic keyword detection
      final basicSymptoms = _detectBasicSymptoms(transcription);
      
      if (basicSymptoms.isEmpty) {
        return {
          'symptoms': [],
          'transcription': transcription,
          'confidence': 0.0,
          'extraction_method': 'keyword',
        };
      }

      // Enhance with AI
      final enhancedExtraction = await _enhanceWithAI(transcription, basicSymptoms);
      
      return {
        'symptoms': enhancedExtraction['symptoms'] ?? basicSymptoms,
        'transcription': transcription,
        'confidence': enhancedExtraction['confidence'] ?? 0.8,
        'extraction_method': enhancedExtraction['method'] ?? 'ai_enhanced',
        'details': enhancedExtraction['details'] ?? {},
        'severity': enhancedExtraction['severity'] ?? 'unknown',
        'duration': enhancedExtraction['duration'] ?? 'unknown',
        'associated_symptoms': enhancedExtraction['associated_symptoms'] ?? [],
      };
    } catch (e) {
      print('❌ Error extracting symptoms: $e');
      return {
        'symptoms': [],
        'transcription': transcription,
        'confidence': 0.0,
        'extraction_method': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Basic symptom detection using keywords
  List<String> _detectBasicSymptoms(String transcription) {
    final lowerTranscription = transcription.toLowerCase();
    final symptoms = <String>[];

    // Comprehensive symptom keywords
    final symptomKeywords = {
      'fever': ['fever', 'temperature', 'hot', 'burning up', 'temp', 'thermometer'],
      'cough': ['cough', 'coughing', 'hack', 'chest', 'throat', 'dry cough', 'wet cough'],
      'vomiting': ['vomit', 'throw up', 'sick', 'nausea', 'puke', 'upset stomach'],
      'diarrhea': ['diarrhea', 'loose stool', 'runny', 'stomach', 'bowel', 'poop'],
      'ear_pain': ['ear pain', 'earache', 'ear hurts', 'pulling ear', 'ear infection'],
      'rash': ['rash', 'spots', 'bumps', 'red skin', 'itchy', 'hives', 'blisters'],
      'headache': ['headache', 'head hurts', 'migraine', 'head pain', 'pressure'],
      'sore_throat': ['sore throat', 'throat hurts', 'swallowing', 'scratchy throat'],
      'breathing_difficulty': ['breathing', 'wheezing', 'shortness', 'chest tight', 'asthma'],
      'runny_nose': ['runny nose', 'congestion', 'stuffy nose', 'sneezing'],
      'fatigue': ['tired', 'fatigue', 'exhausted', 'weak', 'lethargic'],
      'loss_of_appetite': ['not eating', 'loss of appetite', 'refusing food', 'anorexia'],
      'abdominal_pain': ['stomach pain', 'belly ache', 'cramps', 'abdominal pain'],
      'joint_pain': ['joint pain', 'limping', 'swollen joints', 'arthritis'],
      'eye_problems': ['eye pain', 'red eyes', 'swollen eyes', 'vision problems'],
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
  Future<Map<String, dynamic>> _enhanceWithAI(String transcription, List<String> basicSymptoms) async {
    try {
      final primaryApi = _config.primaryVoiceApi;
      final fallbackApi = _config.fallbackVoiceApi;
      
      Map<String, dynamic> result = {};
      
      // Try primary API
      if (primaryApi == 'grok') {
        result = await _callGrokExtraction(transcription, basicSymptoms);
      } else if (primaryApi == 'openai') {
        result = await _callOpenAIExtraction(transcription, basicSymptoms);
      }
      
      // If primary fails and fallback is enabled, try fallback
      if (result.isEmpty && _config.autoFallbackEnabled) {
        if (fallbackApi == 'grok') {
          result = await _callGrokExtraction(transcription, basicSymptoms);
        } else if (fallbackApi == 'openai') {
          result = await _callOpenAIExtraction(transcription, basicSymptoms);
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Error enhancing with AI: $e');
      return {
        'symptoms': basicSymptoms,
        'confidence': 0.7,
        'method': 'keyword_fallback',
      };
    }
  }

  /// Call xAI Grok for symptom extraction
  Future<Map<String, dynamic>> _callGrokExtraction(String transcription, List<String> basicSymptoms) async {
    try {
      final url = Uri.parse('https://api.x.ai/v1/chat/completions');
      
      final prompt = '''
Extract detailed pediatric symptom information from this voice input: "$transcription"

Detected basic symptoms: $basicSymptoms

Please provide a JSON response with the following structure:
{
  "symptoms": ["list", "of", "detected", "symptoms"],
  "severity": "mild|moderate|severe",
  "duration": "extracted duration",
  "associated_symptoms": ["list", "of", "related", "symptoms"],
  "details": {
    "temperature": "extracted temperature if mentioned",
    "medications": "any medications mentioned",
    "triggers": "what triggered or worsened symptoms",
    "relief": "what provides relief"
  },
  "confidence": 0.0-1.0,
  "red_flags": ["list", "of", "red", "flags", "if", "any"]
}

Focus on pediatric-specific symptoms and age-appropriate concerns.
''';

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
              'content': 'You are a pediatric symptom extraction specialist. Extract detailed symptom information from parent voice input and return structured JSON data.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'max_tokens': 800,
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Parse JSON response
        try {
          final jsonData = jsonDecode(content);
          return {
            'symptoms': List<String>.from(jsonData['symptoms'] ?? basicSymptoms),
            'severity': jsonData['severity'] ?? 'unknown',
            'duration': jsonData['duration'] ?? 'unknown',
            'associated_symptoms': List<String>.from(jsonData['associated_symptoms'] ?? []),
            'details': jsonData['details'] ?? {},
            'confidence': jsonData['confidence'] ?? 0.8,
            'red_flags': List<String>.from(jsonData['red_flags'] ?? []),
            'method': 'grok_ai',
          };
        } catch (parseError) {
          print('❌ Error parsing Grok response: $parseError');
          return {
            'symptoms': basicSymptoms,
            'confidence': 0.7,
            'method': 'grok_parse_error',
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

  /// Call OpenAI for symptom extraction
  Future<Map<String, dynamic>> _callOpenAIExtraction(String transcription, List<String> basicSymptoms) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      
      final prompt = '''
Extract detailed pediatric symptom information from this voice input: "$transcription"

Detected basic symptoms: $basicSymptoms

Please provide a JSON response with the following structure:
{
  "symptoms": ["list", "of", "detected", "symptoms"],
  "severity": "mild|moderate|severe",
  "duration": "extracted duration",
  "associated_symptoms": ["list", "of", "related", "symptoms"],
  "details": {
    "temperature": "extracted temperature if mentioned",
    "medications": "any medications mentioned",
    "triggers": "what triggered or worsened symptoms",
    "relief": "what provides relief"
  },
  "confidence": 0.0-1.0,
  "red_flags": ["list", "of", "red", "flags", "if", "any"]
}

Focus on pediatric-specific symptoms and age-appropriate concerns.
''';

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
              'content': 'You are a pediatric symptom extraction specialist. Extract detailed symptom information from parent voice input and return structured JSON data.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'max_tokens': 800,
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Parse JSON response
        try {
          final jsonData = jsonDecode(content);
          return {
            'symptoms': List<String>.from(jsonData['symptoms'] ?? basicSymptoms),
            'severity': jsonData['severity'] ?? 'unknown',
            'duration': jsonData['duration'] ?? 'unknown',
            'associated_symptoms': List<String>.from(jsonData['associated_symptoms'] ?? []),
            'details': jsonData['details'] ?? {},
            'confidence': jsonData['confidence'] ?? 0.8,
            'red_flags': List<String>.from(jsonData['red_flags'] ?? []),
            'method': 'openai_ai',
          };
        } catch (parseError) {
          print('❌ Error parsing OpenAI response: $parseError');
          return {
            'symptoms': basicSymptoms,
            'confidence': 0.7,
            'method': 'openai_parse_error',
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

  /// Extract temperature from transcription
  String? extractTemperature(String transcription) {
    final lowerTranscription = transcription.toLowerCase();
    
    // Temperature patterns
    final patterns = [
      RegExp(r'(\d{2,3})[°\s]*(f|fahrenheit)', caseSensitive: false),
      RegExp(r'(\d{2,3})[°\s]*(c|celsius)', caseSensitive: false),
      RegExp(r'temperature[:\s]*(\d{2,3})', caseSensitive: false),
      RegExp(r'temp[:\s]*(\d{2,3})', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerTranscription);
      if (match != null) {
        final value = int.parse(match.group(1)!);
        final unit = match.group(2)?.toLowerCase() ?? 'f';
        
        // Convert Celsius to Fahrenheit if needed
        if (unit == 'c') {
          final fahrenheit = (value * 9/5) + 32;
          return '${fahrenheit.round()}°F';
        } else {
          return '${value}°F';
        }
      }
    }
    
    return null;
  }

  /// Extract duration from transcription
  String? extractDuration(String transcription) {
    final lowerTranscription = transcription.toLowerCase();
    
    // Duration patterns
    final patterns = [
      RegExp(r'(\d+)\s*(day|days)', caseSensitive: false),
      RegExp(r'(\d+)\s*(hour|hours)', caseSensitive: false),
      RegExp(r'(\d+)\s*(week|weeks)', caseSensitive: false),
      RegExp(r'(\d+)\s*(month|months)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerTranscription);
      if (match != null) {
        final value = match.group(1)!;
        final unit = match.group(2)!;
        return '$value $unit';
      }
    }
    
    return null;
  }

  /// Extract medications from transcription
  List<String> extractMedications(String transcription) {
    final lowerTranscription = transcription.toLowerCase();
    final medications = <String>[];
    
    // Common pediatric medications
    final medKeywords = [
      'tylenol', 'acetaminophen', 'ibuprofen', 'motrin', 'advil',
      'aspirin', 'benadryl', 'claritin', 'zyrtec', 'pepto',
      'tums', 'mylanta', 'pedialyte', 'gatorade', 'vitamin',
      'antibiotic', 'amoxicillin', 'penicillin', 'azithromycin',
    ];
    
    for (final med in medKeywords) {
      if (lowerTranscription.contains(med)) {
        medications.add(med);
      }
    }
    
    return medications;
  }

  /// Check for red flags in transcription
  List<String> detectRedFlags(String transcription) {
    final lowerTranscription = transcription.toLowerCase();
    final redFlags = <String>[];
    
    // Red flag keywords
    final redFlagKeywords = [
      'blue lips', 'blue face', 'cyanosis',
      'difficulty breathing', 'struggling to breathe',
      'unconscious', 'unresponsive', 'lethargic',
      'severe pain', 'extreme pain', 'worst pain',
      'blood', 'bleeding', 'bruising',
      'high fever', 'fever over 104', 'fever 105',
      'dehydrated', 'no tears', 'dry mouth',
      'stiff neck', 'neck stiffness',
      'seizure', 'convulsion', 'shaking',
    ];
    
    for (final flag in redFlagKeywords) {
      if (lowerTranscription.contains(flag)) {
        redFlags.add(flag);
      }
    }
    
    return redFlags;
  }
}

// Example usage:
// final extractionService = SymptomExtractionService.instance;
// final result = await extractionService.extractSymptoms('My child has a fever of 102 degrees for 2 days');
// print('Extracted symptoms: ${result['symptoms']}'); 