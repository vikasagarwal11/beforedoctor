import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SymptomExtractionService {
  final String _openaiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _grokApiKey = dotenv.env['XAI_GROK_API_KEY'] ?? '';
  
  // Symptom keywords for rule-based extraction
  final Map<String, List<String>> _symptomKeywords = {
    'fever': ['fever', 'temp', 'temperature', 'hot', 'burning up', 'high temp'],
    'cough': ['cough', 'coughing', 'hack', 'hacking'],
    'vomiting': ['vomit', 'vomiting', 'throw up', 'throwing up', 'puke', 'puking'],
    'diarrhea': ['diarrhea', 'diarrhoea', 'loose stool', 'runny poop', 'watery stool'],
    'headache': ['headache', 'head ache', 'head pain', 'migraine'],
    'abdominal_pain': ['stomach ache', 'tummy ache', 'belly pain', 'abdominal pain'],
    'fatigue': ['tired', 'exhausted', 'lethargic', 'weak', 'no energy'],
    'rash': ['rash', 'hives', 'skin rash', 'red spots', 'bumps'],
    'runny_nose': ['runny nose', 'dripping nose', 'snot', 'nasal discharge'],
    'sore_throat': ['sore throat', 'throat pain', 'difficulty swallowing'],
    'ear_pain': ['ear ache', 'ear pain', 'ear infection'],
    'difficulty_breathing': ['wheezing', 'shortness of breath', 'trouble breathing'],
    'dehydration': ['dry mouth', 'no tears', 'sunken eyes', 'decreased urination'],
  };

  /// Extract symptoms from voice input using AI and rule-based methods
  Future<SymptomExtractionResult> extractSymptoms(String voiceInput) async {
    try {
      // First try AI-based extraction
      final aiResult = await _extractWithAI(voiceInput);
      
      if (aiResult.isSuccessful && aiResult.symptoms.isNotEmpty) {
        return aiResult;
      }
      
      // Fallback to rule-based extraction
      return _extractWithRules(voiceInput);
    } catch (e) {
      // Final fallback to rule-based
      return _extractWithRules(voiceInput);
    }
  }

  /// Extract symptoms using AI (OpenAI or Grok)
  Future<SymptomExtractionResult> _extractWithAI(String voiceInput) async {
    try {
      final prompt = '''
Extract pediatric symptoms from the following voice input. Return only a JSON array of symptom names in lowercase, no explanations.

Voice input: "$voiceInput"

Expected format: ["symptom1", "symptom2", "symptom3"]

Common pediatric symptoms to look for:
- fever, cough, vomiting, diarrhea, headache, abdominal_pain, fatigue, rash, runny_nose, sore_throat, ear_pain, difficulty_breathing, dehydration, nausea, body_aches, chills, loss_appetite, irritability, congestion, wheezing, itching, swelling, joint_pain, sensitivity_light, sensitivity_sound, chest_pain, dry_mouth, decreased_urination, dizziness, lethargy, behavioral_changes

Return only the JSON array:
''';

      // Try OpenAI first
      try {
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_openaiApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4o',
            'messages': [
              {'role': 'system', 'content': 'You are a pediatric symptom extraction assistant. Return only valid JSON arrays.'},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.1,
            'max_tokens': 200,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'];
          final symptoms = _parseAIResponse(content);
          
          if (symptoms.isNotEmpty) {
            return SymptomExtractionResult(
              symptoms: symptoms,
              confidence: 0.85,
              method: 'openai',
              isSuccessful: true,
            );
          }
        }
      } catch (e) {
        // Log error but continue to fallback
      }

      // Try Grok as fallback
      try {
        final response = await http.post(
          Uri.parse('https://api.grok.x.ai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_grokApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'grok-1',
            'messages': [
              {'role': 'system', 'content': 'You are a pediatric symptom extraction assistant. Return only valid JSON arrays.'},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.1,
            'max_tokens': 200,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'];
          final symptoms = _parseAIResponse(content);
          
          if (symptoms.isNotEmpty) {
            return SymptomExtractionResult(
              symptoms: symptoms,
              confidence: 0.80,
              method: 'grok',
              isSuccessful: true,
            );
          }
        }
      } catch (e) {
        // Log error but continue to fallback
      }

      // If AI fails, return empty result
      return SymptomExtractionResult(
        symptoms: [],
        confidence: 0.0,
        method: 'ai_failed',
        isSuccessful: false,
      );
    } catch (e) {
      return SymptomExtractionResult(
        symptoms: [],
        confidence: 0.0,
        method: 'ai_error',
        isSuccessful: false,
        error: e.toString(),
      );
    }
  }

  /// Parse AI response to extract symptoms
  List<String> _parseAIResponse(String response) {
    try {
      // Clean the response
      final cleanResponse = response.trim();
      
      // Try to find JSON array
      final jsonMatch = RegExp(r'\[.*\]').firstMatch(cleanResponse);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final List<dynamic> symptoms = jsonDecode(jsonString);
        return symptoms.map((s) => s.toString().toLowerCase()).toList();
      }
      
      // Fallback: try to extract symptoms from text
      final symptoms = <String>[];
      final lowerResponse = cleanResponse.toLowerCase();
      
      for (final entry in _symptomKeywords.entries) {
        for (final keyword in entry.value) {
          if (lowerResponse.contains(keyword)) {
            symptoms.add(entry.key);
            break;
          }
        }
      }
      
      return symptoms;
    } catch (e) {
      return [];
    }
  }

  /// Extract symptoms using rule-based keyword matching
  SymptomExtractionResult _extractWithRules(String voiceInput) {
    final symptoms = <String>[];
    final lowerInput = voiceInput.toLowerCase();
    
    // Extract symptoms using keyword matching
    for (final entry in _symptomKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerInput.contains(keyword)) {
          symptoms.add(entry.key);
          break;
        }
      }
    }
    
    // Extract additional context
    final context = _extractContext(lowerInput);
    
    return SymptomExtractionResult(
      symptoms: symptoms,
      confidence: symptoms.isNotEmpty ? 0.6 : 0.0,
      method: 'rule_based',
      isSuccessful: symptoms.isNotEmpty,
      context: context,
    );
  }

  /// Extract additional context from voice input
  Map<String, dynamic> _extractContext(String lowerInput) {
    final context = <String, dynamic>{};
    
    // Extract temperature
    final tempMatch = RegExp(r'(\d{2,3})[°\s]*(f|fahrenheit|temp|temperature)').firstMatch(lowerInput);
    if (tempMatch != null) {
      context['temperature'] = tempMatch.group(1);
    }
    
    // Extract duration
    if (lowerInput.contains('day') || lowerInput.contains('days')) {
      final dayMatch = RegExp(r'(\d+)\s*days?').firstMatch(lowerInput);
      if (dayMatch != null) {
        context['duration_days'] = int.tryParse(dayMatch.group(1)!) ?? 1;
      } else if (lowerInput.contains('today')) {
        context['duration_days'] = 1;
      }
    }
    
    // Extract severity indicators
    if (lowerInput.contains('severe') || lowerInput.contains('bad') || lowerInput.contains('terrible')) {
      context['severity'] = 'severe';
    } else if (lowerInput.contains('mild') || lowerInput.contains('slight') || lowerInput.contains('little')) {
      context['severity'] = 'mild';
    } else {
      context['severity'] = 'moderate';
    }
    
    // Extract frequency
    if (lowerInput.contains('constant') || lowerInput.contains('all the time')) {
      context['frequency'] = 'constant';
    } else if (lowerInput.contains('sometimes') || lowerInput.contains('occasional')) {
      context['frequency'] = 'occasional';
    } else {
      context['frequency'] = 'intermittent';
    }
    
    return context;
  }

  /// Get all available symptom categories
  List<String> getAvailableSymptoms() {
    return _symptomKeywords.keys.toList();
  }

  /// Get symptom keywords for a specific symptom
  List<String> getSymptomKeywords(String symptom) {
    return _symptomKeywords[symptom] ?? [];
  }

  /// Validate if a symptom is recognized
  bool isValidSymptom(String symptom) {
    return _symptomKeywords.containsKey(symptom.toLowerCase());
  }

  /// Get symptom synonyms
  Map<String, List<String>> getSymptomSynonyms() {
    return Map.from(_symptomKeywords);
  }
}

/// Result class for symptom extraction
class SymptomExtractionResult {
  final List<String> symptoms;
  final double confidence;
  final String method;
  final bool isSuccessful;
  final Map<String, dynamic>? context;
  final String? error;

  SymptomExtractionResult({
    required this.symptoms,
    required this.confidence,
    required this.method,
    required this.isSuccessful,
    this.context,
    this.error,
  });

  /// Get primary symptoms (most confident)
  List<String> get primarySymptoms {
    return symptoms.take(3).toList(); // Top 3 symptoms
  }

  /// Get secondary symptoms (less confident)
  List<String> get secondarySymptoms {
    return symptoms.length > 3 ? symptoms.skip(3).toList() : [];
  }

  /// Check if extraction was successful
  bool get hasSymptoms => symptoms.isNotEmpty;

  /// Get confidence level description
  String get confidenceDescription {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    if (confidence >= 0.4) return 'Low';
    return 'Very Low';
  }

  /// Get method description
  String get methodDescription {
    switch (method) {
      case 'openai':
        return 'AI (OpenAI)';
      case 'grok':
        return 'AI (Grok)';
      case 'rule_based':
        return 'Rule-based';
      case 'ai_failed':
        return 'AI Failed';
      case 'ai_error':
        return 'AI Error';
      default:
        return 'Unknown';
    }
  }
} 