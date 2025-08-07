import 'package:logger/logger.dart';
import 'ai_model_service.dart';

class AIEnhancedVoiceService {
  static final Logger _logger = Logger();
  
  /// Process voice input with AI enhancement
  static Future<Map<String, dynamic>> processVoiceWithAI(String voiceInput) async {
    try {
      _logger.i('Processing voice input with AI: ${voiceInput.substring(0, voiceInput.length > 50 ? 50 : voiceInput.length)}...');
      
      // Predict symptom from voice input
      final predictedSymptom = AIModelService.predictSymptom(voiceInput);
      
      // Assess risk level
      final riskLevel = AIModelService.assessRisk(voiceInput);
      
      // Extract additional information
      final extractedInfo = _extractSymptomInfo(voiceInput);
      
      // Generate AI insights
      final aiInsights = _generateAIInsights(predictedSymptom, riskLevel, extractedInfo);
      
      return {
        'original_input': voiceInput,
        'predicted_symptom': predictedSymptom,
        'risk_level': riskLevel,
        'extracted_info': extractedInfo,
        'ai_insights': aiInsights,
        'confidence_score': _calculateConfidence(voiceInput, predictedSymptom),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('Error processing voice with AI: $e');
      return {
        'original_input': voiceInput,
        'predicted_symptom': 'unknown',
        'risk_level': 'medium',
        'extracted_info': {},
        'ai_insights': 'Unable to process voice input',
        'confidence_score': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Extract structured information from voice input
  static Map<String, dynamic> _extractSymptomInfo(String voiceInput) {
    final input = voiceInput.toLowerCase();
    final info = <String, dynamic>{};
    
    // Extract temperature if mentioned
    final tempMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:degree|f|fahrenheit|temp|temperature)').firstMatch(input);
    if (tempMatch != null) {
      info['temperature'] = double.tryParse(tempMatch.group(1) ?? '');
    }
    
    // Extract duration
    final durationMatch = RegExp(r'(\d+)\s*(?:hour|day|week|month)s?').firstMatch(input);
    if (durationMatch != null) {
      info['duration'] = durationMatch.group(0);
    }
    
    // Extract severity indicators
    if (input.contains('severe') || input.contains('very bad') || input.contains('terrible')) {
      info['severity'] = 'severe';
    } else if (input.contains('mild') || input.contains('slight') || input.contains('minor')) {
      info['severity'] = 'mild';
    } else {
      info['severity'] = 'moderate';
    }
    
    // Extract age group if mentioned
    if (input.contains('baby') || input.contains('infant')) {
      info['age_group'] = 'infant';
    } else if (input.contains('toddler') || input.contains('2 year') || input.contains('3 year')) {
      info['age_group'] = 'toddler';
    } else if (input.contains('child') || input.contains('kid')) {
      info['age_group'] = 'child';
    } else if (input.contains('teen') || input.contains('adolescent')) {
      info['age_group'] = 'adolescent';
    }
    
    return info;
  }
  
  /// Generate AI insights based on predicted symptom and risk level
  static Map<String, dynamic> _generateAIInsights(String symptom, String riskLevel, Map<String, dynamic> extractedInfo) {
    final insights = <String, dynamic>{};
    
    // Symptom-specific insights
    switch (symptom.toLowerCase()) {
      case 'fever':
        insights['symptom_insight'] = 'Fever is often a sign of infection. Monitor temperature and hydration.';
        insights['watch_for'] = ['Temperature above 103°F', 'Dehydration', 'Lethargy'];
        break;
      case 'cough':
        insights['symptom_insight'] = 'Cough can be caused by various factors including cold, allergies, or infection.';
        insights['watch_for'] = ['Difficulty breathing', 'Chest pain', 'Persistent cough'];
        break;
      case 'headache':
        insights['symptom_insight'] = 'Headaches in children should be evaluated, especially if severe or persistent.';
        insights['watch_for'] = ['Severe pain', 'Vision changes', 'Nausea with headache'];
        break;
      default:
        insights['symptom_insight'] = 'Monitor symptoms and seek medical attention if they worsen.';
        insights['watch_for'] = ['Worsening symptoms', 'New symptoms', 'Dehydration'];
    }
    
    // Risk-based recommendations
    switch (riskLevel.toLowerCase()) {
      case 'high':
        insights['urgency'] = 'Seek immediate medical attention';
        insights['action_required'] = true;
        break;
      case 'medium':
        insights['urgency'] = 'Monitor closely and consult healthcare provider if symptoms persist';
        insights['action_required'] = false;
        break;
      case 'low':
        insights['urgency'] = 'Continue monitoring, symptoms may resolve on their own';
        insights['action_required'] = false;
        break;
    }
    
    // Add extracted info to insights
    if (extractedInfo.isNotEmpty) {
      insights['extracted_details'] = extractedInfo;
    }
    
    return insights;
  }
  
  /// Calculate confidence score for the prediction
  static double _calculateConfidence(String voiceInput, String predictedSymptom) {
    final input = voiceInput.toLowerCase();
    final symptom = predictedSymptom.toLowerCase();
    
    // Simple confidence calculation based on keyword matching
    double confidence = 0.0;
    
    if (symptom == 'fever' && (input.contains('fever') || input.contains('temperature'))) {
      confidence = 0.9;
    } else if (symptom == 'cough' && input.contains('cough')) {
      confidence = 0.85;
    } else if (symptom == 'headache' && input.contains('headache')) {
      confidence = 0.8;
    } else if (symptom == 'nausea' && input.contains('nausea')) {
      confidence = 0.75;
    } else if (symptom == 'vomiting' && input.contains('vomit')) {
      confidence = 0.8;
    } else if (symptom == 'diarrhea' && input.contains('diarrhea')) {
      confidence = 0.75;
    } else {
      confidence = 0.5; // Default confidence for general symptoms
    }
    
    return confidence;
  }
  
  /// Get treatment recommendation with AI enhancement
  static String getTreatmentRecommendation(String symptom, String ageGroup, String severity) {
    return AIModelService.recommendTreatment(symptom, ageGroup, severity);
  }
  
  /// Check if AI models are loaded
  static bool get isAIAvailable => AIModelService.modelsLoaded;
  
  /// Get AI model status
  static Map<String, dynamic> getAIModelStatus() {
    return {
      'models_loaded': AIModelService.modelsLoaded,
      'symptom_classifier': AIModelService.symptomClassifier,
      'risk_assessor': AIModelService.riskAssessor,
    };
  }
} 