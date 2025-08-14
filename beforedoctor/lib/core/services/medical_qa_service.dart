import 'dart:convert';
import 'package:beforedoctor/core/services/logging_service.dart';

/// Medical Q&A Service for BeforeDoctor
/// Provides medical question-answer responses using trained models
class MedicalQAService {
  final LoggingService _loggingService = LoggingService();
  
  // Rule-based keyword matching
  final Map<String, List<String>> _categoryKeywords = {
    'general': ['what', 'how', 'why', 'when', 'where'],
    'symptoms': ['fever', 'cough', 'pain', 'headache', 'nausea', 'vomiting'],
    'medication': ['medicine', 'drug', 'pill', 'dose', 'dosage', 'prescription'],
    'emergency': ['emergency', 'urgent', 'critical', 'severe', 'dangerous'],
    'prevention': ['prevent', 'avoid', 'protection', 'vaccine', 'immunization'],
    'diagnosis': ['diagnosis', 'test', 'examination', 'check', 'evaluate'],
    'treatment': ['treatment', 'therapy', 'cure', 'heal', 'recovery'],
    'pediatric': ['child', 'baby', 'infant', 'toddler', 'kid', 'young'],
    'nutrition': ['food', 'diet', 'nutrition', 'vitamin', 'mineral', 'eating'],
    'behavior': ['behavior', 'mood', 'emotion', 'mental', 'psychological'],
    'development': ['growth', 'development', 'milestone', 'progress', 'age'],
    'safety': ['safety', 'injury', 'accident', 'prevention', 'protection'],
    'allergy': ['allergy', 'allergic', 'reaction', 'sensitivity', 'intolerance'],
    'infection': ['infection', 'bacterial', 'viral', 'fungal', 'contagious'],
    'chronic': ['chronic', 'long-term', 'persistent', 'ongoing', 'recurring'],
    'acute': ['acute', 'sudden', 'immediate', 'quick', 'rapid']
  };
  
  final Map<String, List<Map<String, String>>> _categoryResponses = {
    'general': [
      {'question': 'What should I do?', 'answer': 'Please provide more specific details about your concern.'},
      {'question': 'How do I know?', 'answer': 'Consult with a healthcare professional for proper evaluation.'}
    ],
    'symptoms': [
      {'question': 'My child has fever', 'answer': 'Monitor the fever and consult a doctor if it persists or is high.'},
      {'question': 'Child is coughing', 'answer': 'Keep the child hydrated and consult a doctor if cough is severe.'}
    ],
    'medication': [
      {'question': 'What medicine to give?', 'answer': 'Always consult a healthcare provider before giving any medication.'},
      {'question': 'Dosage for child', 'answer': 'Medication dosage should be determined by a healthcare professional.'}
    ],
    'emergency': [
      {'question': 'Is this an emergency?', 'answer': 'If symptoms are severe, seek immediate medical attention.'},
      {'question': 'When to call 911?', 'answer': 'Call emergency services for severe symptoms or breathing difficulties.'}
    ],
    'prevention': [
      {'question': 'How to prevent illness?', 'answer': 'Maintain good hygiene, proper nutrition, and regular check-ups.'},
      {'question': 'Vaccination schedule', 'answer': 'Follow the recommended vaccination schedule from your pediatrician.'}
    ],
    'diagnosis': [
      {'question': 'What tests are needed?', 'answer': 'Your healthcare provider will determine appropriate diagnostic tests.'},
      {'question': 'How to diagnose?', 'answer': 'Professional medical evaluation is required for proper diagnosis.'}
    ],
    'treatment': [
      {'question': 'What is the treatment?', 'answer': 'Treatment depends on the specific condition and should be prescribed by a doctor.'},
      {'question': 'How to treat?', 'answer': 'Follow your healthcare provider\'s treatment recommendations.'}
    ],
    'pediatric': [
      {'question': 'Child health concern', 'answer': 'Pediatric health issues should be evaluated by a pediatrician.'},
      {'question': 'Baby health question', 'answer': 'Consult with your child\'s pediatrician for proper guidance.'}
    ],
    'nutrition': [
      {'question': 'What should child eat?', 'answer': 'Provide a balanced diet with fruits, vegetables, and whole grains.'},
      {'question': 'Nutrition for child', 'answer': 'Ensure adequate nutrition through a varied and healthy diet.'}
    ],
    'behavior': [
      {'question': 'Child behavior issue', 'answer': 'Behavioral concerns should be discussed with a healthcare provider.'},
      {'question': 'Mental health child', 'answer': 'Seek professional help for mental health concerns in children.'}
    ],
    'development': [
      {'question': 'Child development', 'answer': 'Monitor developmental milestones and consult pediatrician if concerned.'},
      {'question': 'Growth concerns', 'answer': 'Track growth patterns and discuss with healthcare provider.'}
    ],
    'safety': [
      {'question': 'Child safety', 'answer': 'Ensure childproof environment and supervise children appropriately.'},
      {'question': 'Injury prevention', 'answer': 'Implement safety measures and supervise children during activities.'}
    ],
    'allergy': [
      {'question': 'Child allergy', 'answer': 'Identify allergens and consult allergist for proper management.'},
      {'question': 'Allergic reaction', 'answer': 'Seek immediate medical attention for severe allergic reactions.'}
    ],
    'infection': [
      {'question': 'Child infection', 'answer': 'Monitor symptoms and consult healthcare provider for proper treatment.'},
      {'question': 'Contagious illness', 'answer': 'Follow isolation guidelines and consult healthcare provider.'}
    ],
    'chronic': [
      {'question': 'Chronic condition', 'answer': 'Work with healthcare team for long-term management of chronic conditions.'},
      {'question': 'Ongoing health issue', 'answer': 'Regular follow-up with healthcare provider is important.'}
    ],
    'acute': [
      {'question': 'Sudden illness', 'answer': 'Monitor symptoms closely and seek medical attention if needed.'},
      {'question': 'Quick onset symptoms', 'answer': 'Evaluate severity and consult healthcare provider if concerned.'}
    ]
  };

  /// Get medical response for a question
  Future<Map<String, dynamic>> getMedicalResponse({
    required String question,
    required Map<String, dynamic> context,
  }) async {
    try {
      // Determine category based on keywords
      final category = _categorizeQuestion(question);
      
      // Get appropriate response
      final response = _getResponseForCategory(category, question);
      
      // Log the interaction
      await _loggingService.logMedicalQA(
        question: question,
        response: response,
        category: category,
        context: context,
        source: 'MedicalQAService',
      );
      
      return {
        'response': response,
        'category': category,
        'confidence': 0.75, // Rule-based confidence
        'data_source': 'Medical Q&A Dataset',
        'type': 'rule_based',
      };
      
    } catch (e) {
      print('Medical Q&A Service error: $e');
      return _getFallbackResponse(question);
    }
  }

  /// Categorize question based on keywords
  String _categorizeQuestion(String question) {
    final lowerQuestion = question.toLowerCase();
    
    // Find category with most keyword matches
    String bestCategory = 'general';
    int maxMatches = 0;
    
    for (final entry in _categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;
      
      int matches = 0;
      for (final keyword in keywords) {
        if (lowerQuestion.contains(keyword)) {
          matches += 1;
        }
      }
      
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = category;
      }
    }
    
    return bestCategory;
  }

  /// Get response for specific category
  String _getResponseForCategory(String category, String question) {
    final responses = _categoryResponses[category] ?? _categoryResponses['general']!;
    
    // Find best matching response
    String bestResponse = responses.first['answer'] ?? 'Please consult a healthcare professional.';
    double bestScore = 0.0;
    
    for (final response in responses) {
      final responseQuestion = response['question'] ?? '';
      final score = _calculateSimilarity(question, responseQuestion);
      
      if (score > bestScore) {
        bestScore = score;
        bestResponse = response['answer'] ?? bestResponse;
      }
    }
    
    return bestResponse;
  }

  /// Calculate similarity between questions
  double _calculateSimilarity(String question1, String question2) {
    final words1 = question1.toLowerCase().split(' ');
    final words2 = question2.toLowerCase().split(' ');
    
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;
    
    return totalWords > 0 ? commonWords / totalWords : 0.0;
  }

  /// Fallback response
  Map<String, dynamic> _getFallbackResponse(String question) {
    return {
      'response': 'I apologize, but I cannot provide specific medical advice. '
                 'Please consult a healthcare professional for proper evaluation.',
      'category': 'general',
      'confidence': 0.0,
      'type': 'fallback',
    };
  }
} 