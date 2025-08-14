import 'dart:convert';
import 'package:beforedoctor/core/services/logging_service.dart';
import 'package:beforedoctor/core/services/cdc_risk_assessment_service.dart';
import 'package:beforedoctor/core/services/medical_qa_service.dart';

/// Orchestrates AI responses by combining CDC risk assessment and Medical Q&A
/// This service keeps voice_logger_screen.dart lean by handling all AI logic
class AIResponseOrchestrator {
  final LoggingService _loggingService = LoggingService();
  final CDCRiskAssessmentService _cdcService = CDCRiskAssessmentService();
  final MedicalQAService _medicalQAService = MedicalQAService();

  /// Get comprehensive AI response combining risk assessment and medical Q&A
  Future<Map<String, dynamic>> getComprehensiveResponse({
    required List<String> symptoms,
    required Map<String, dynamic> childContext,
    String? userQuestion,
  }) async {
    try {
      // Step 1: CDC Risk Assessment
      final cdcAssessment = await _cdcService.assessRisk(
        childAge: childContext['child_age'] ?? 5,
        symptoms: symptoms,
        context: childContext,
      );

      // Step 2: Medical Q&A Response (if question provided)
      Map<String, dynamic> medicalResponse = {};
      if (userQuestion != null && userQuestion.isNotEmpty) {
        medicalResponse = await _medicalQAService.getMedicalResponse(
          question: userQuestion,
          context: childContext,
        );
      }

      // Step 3: Combine responses
      final combinedResponse = _combineResponses(cdcAssessment, medicalResponse);

      // Step 4: Log the interaction
      await _loggingService.logAIOrchestration(
        symptoms: symptoms,
        question: userQuestion,
        cdcAssessment: cdcAssessment,
        medicalResponse: medicalResponse,
        combinedResponse: combinedResponse,
      );

      return combinedResponse;

    } catch (e) {
      print('❌ AI Response Orchestrator error: $e');
      return _getFallbackResponse(symptoms, userQuestion);
    }
  }

  /// Get risk assessment only (for symptom-only inputs)
  Future<Map<String, dynamic>> getRiskAssessment({
    required List<String> symptoms,
    required Map<String, dynamic> childContext,
  }) async {
    try {
      final assessment = await _cdcService.assessRisk(
        childAge: childContext['child_age'] ?? 5,
        symptoms: symptoms,
        context: childContext,
      );

      await _loggingService.logRiskAssessment(
        childAge: childContext['child_age'] ?? 5,
        symptoms: symptoms,
        riskLevel: assessment['risk_level'],
        riskScore: assessment['risk_score'],
        source: 'AI_Orchestrator',
      );

      return assessment;

    } catch (e) {
      print('❌ Risk Assessment error: $e');
      return _getFallbackRiskAssessment(symptoms);
    }
  }

  /// Get medical Q&A response only (for question-only inputs)
  Future<Map<String, dynamic>> getMedicalResponse({
    required String question,
    required Map<String, dynamic> context,
  }) async {
    try {
      final response = await _medicalQAService.getMedicalResponse(
        question: question,
        context: context,
      );

      await _loggingService.logMedicalQA(
        question: question,
        response: response['response'],
        category: response['category'],
        context: context,
        source: 'AI_Orchestrator',
      );

      return response;

    } catch (e) {
      print('❌ Medical Q&A error: $e');
      return _getFallbackMedicalResponse(question);
    }
  }

  /// Combine CDC and Medical responses intelligently
  Map<String, dynamic> _combineResponses(
    Map<String, dynamic> cdcAssessment,
    Map<String, dynamic> medicalResponse,
  ) {
    final riskLevel = cdcAssessment['risk_level'] ?? 'unknown';
    final medicalAnswer = medicalResponse['response'] ?? '';

    // Build comprehensive response
    String combinedResponse = '';
    List<String> recommendations = [];

    // Add risk-based guidance
    switch (riskLevel) {
      case 'critical':
        combinedResponse += '🚨 **URGENT**: ';
        recommendations.add('Seek immediate medical attention');
        break;
      case 'high':
        combinedResponse += '⚠️ **High Risk**: ';
        recommendations.add('Schedule doctor appointment within 24 hours');
        break;
      case 'medium':
        combinedResponse += '📋 **Moderate Risk**: ';
        recommendations.add('Monitor symptoms closely');
        break;
      case 'low':
        combinedResponse += '✅ **Low Risk**: ';
        recommendations.add('Continue monitoring at home');
        break;
      default:
        combinedResponse += 'ℹ️ **Assessment**: ';
    }

    // Add medical Q&A response if available
    if (medicalAnswer.isNotEmpty) {
      combinedResponse += medicalAnswer;
    } else {
      combinedResponse += 'Based on the symptoms provided, ';
      combinedResponse += cdcAssessment['recommendations']?.join(' ') ?? 
                        'please consult a healthcare professional.';
    }

    // Add risk-specific recommendations
    if (cdcAssessment['recommendations'] != null) {
      recommendations.addAll(cdcAssessment['recommendations']);
    }

    return {
      'response': combinedResponse,
      'risk_level': riskLevel,
      'risk_score': cdcAssessment['risk_score'],
      'recommendations': recommendations,
      'data_sources': {
        'cdc': 'CDC Real Dataset',
        'medical_qa': medicalResponse['data_source'] ?? 'Medical Q&A Dataset',
      },
      'confidence': _calculateCombinedConfidence(cdcAssessment, medicalResponse),
      'type': 'comprehensive_assessment',
    };
  }

  /// Calculate combined confidence score
  double _calculateCombinedConfidence(
    Map<String, dynamic> cdcAssessment,
    Map<String, dynamic> medicalResponse,
  ) {
    final cdcConfidence = cdcAssessment['confidence'] ?? 0.8;
    final medicalConfidence = medicalResponse['confidence'] ?? 0.7;
    
    // Weight CDC assessment more heavily for risk assessment
    return (cdcConfidence * 0.7) + (medicalConfidence * 0.3);
  }

  /// Fallback response when services fail
  Map<String, dynamic> _getFallbackResponse(List<String> symptoms, String? question) {
    return {
      'response': 'I apologize, but I cannot provide medical advice at this time. '
                 'Please consult a healthcare professional for proper evaluation.',
      'risk_level': 'unknown',
      'risk_score': 0.0,
      'recommendations': ['Consult healthcare professional'],
      'confidence': 0.0,
      'type': 'fallback',
    };
  }

  /// Fallback risk assessment
  Map<String, dynamic> _getFallbackRiskAssessment(List<String> symptoms) {
    return {
      'risk_level': 'unknown',
      'risk_score': 0.0,
      'recommendations': ['Consult healthcare professional'],
      'confidence': 0.0,
      'type': 'fallback',
    };
  }

  /// Fallback medical response
  Map<String, dynamic> _getFallbackMedicalResponse(String question) {
    return {
      'response': 'I apologize, but I cannot provide medical advice. '
                 'Please consult a healthcare professional.',
      'category': 'general',
      'confidence': 0.0,
      'type': 'fallback',
    };
  }
} 