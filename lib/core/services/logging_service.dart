import 'dart:convert';

/// Logging Service for BeforeDoctor
/// Handles logging of AI interactions and assessments
class LoggingService {
  
  /// Log AI orchestration interaction
  Future<void> logAIOrchestration({
    required List<String> symptoms,
    String? question,
    required Map<String, dynamic> cdcAssessment,
    required Map<String, dynamic> medicalResponse,
    required Map<String, dynamic> combinedResponse,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'ai_orchestration',
        'symptoms': symptoms,
        'question': question,
        'cdc_assessment': cdcAssessment,
        'medical_response': medicalResponse,
        'combined_response': combinedResponse,
      };
      
      // In a real app, this would be sent to Firebase Analytics or similar
      print('📊 AI Orchestration Log: ${jsonEncode(logEntry)}');
    } catch (e) {
      print('Logging error: $e');
    }
  }
  
  /// Log risk assessment
  Future<void> logRiskAssessment({
    required int childAge,
    required List<String> symptoms,
    required String riskLevel,
    required double riskScore,
    required String source,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'risk_assessment',
        'child_age': childAge,
        'symptoms': symptoms,
        'risk_level': riskLevel,
        'risk_score': riskScore,
        'source': source,
      };
      
      print('📊 Risk Assessment Log: ${jsonEncode(logEntry)}');
    } catch (e) {
      print('Logging error: $e');
    }
  }
  
  /// Log medical Q&A interaction
  Future<void> logMedicalQA({
    required String question,
    required String response,
    required String category,
    required Map<String, dynamic> context,
    required String source,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'medical_qa',
        'question': question,
        'response': response,
        'category': category,
        'context': context,
        'source': source,
      };
      
      print('📊 Medical Q&A Log: ${jsonEncode(logEntry)}');
    } catch (e) {
      print('Logging error: $e');
    }
  }
} 