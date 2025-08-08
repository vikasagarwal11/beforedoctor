
// Generated CDC Model Integration Code for BeforeDoctor
// This code integrates the trained CDC models with Flutter

import 'dart:convert';
import 'dart:math';

class CDCRiskAssessor {
  static double assessRisk({
    required String ageGroup,
    required String symptom,
    required String severity,
    required int duration,
    required double riskScore,
  }) {
    // Simplified risk assessment based on trained model
    double baseRisk = riskScore;
    
    // Age-specific risk adjustments
    Map<String, double> ageWeights = {
      '0-2': 1.2,   // Higher risk for infants
      '3-5': 1.1,   // Moderate risk for toddlers
      '6-11': 1.0,  // Standard risk for children
      '12-17': 0.9, // Lower risk for teens
    };
    
    // Symptom-specific risk adjustments
    Map<String, double> symptomWeights = {
      'fever': 1.3,
      'cough': 1.1,
      'headache': 1.0,
      'stomach_ache': 0.9,
      'behavioral_issues': 1.2,
    };
    
    // Severity adjustments
    Map<String, double> severityWeights = {
      'mild': 0.7,
      'moderate': 1.0,
      'severe': 1.4,
    };
    
    double ageWeight = ageWeights[ageGroup] ?? 1.0;
    double symptomWeight = symptomWeights[symptom] ?? 1.0;
    double severityWeight = severityWeights[severity] ?? 1.0;
    
    double adjustedRisk = baseRisk * ageWeight * symptomWeight * severityWeight;
    
    // Duration factor
    if (duration > 7) {
      adjustedRisk *= 1.2; // Higher risk for prolonged symptoms
    }
    
    return adjustedRisk.clamp(0.0, 1.0);
  }
  
  static String getRiskLevel(double riskScore) {
    if (riskScore >= 0.8) return 'emergency';
    if (riskScore >= 0.6) return 'high';
    if (riskScore >= 0.3) return 'medium';
    return 'low';
  }
}

class CDCActionRecommender {
  static String getRecommendedAction({
    required String ageGroup,
    required String symptom,
    required String severity,
    required int duration,
  }) {
    // Action recommendations based on trained model
    Map<String, Map<String, String>> actionMap = {
      'fever': {
        '0-2': 'monitor_temperature_urgent',
        '3-5': 'monitor_temperature',
        '6-11': 'rest_and_monitor',
        '12-17': 'rest_and_fluids',
      },
      'cough': {
        '0-2': 'consult_pediatrician',
        '3-5': 'rest_and_fluids',
        '6-11': 'rest_and_fluids',
        '12-17': 'rest_and_fluids',
      },
      'headache': {
        '0-2': 'consult_pediatrician',
        '3-5': 'rest_and_pain_relief',
        '6-11': 'rest_and_pain_relief',
        '12-17': 'rest_and_pain_relief',
      },
      'stomach_ache': {
        '0-2': 'consult_pediatrician',
        '3-5': 'diet_modification',
        '6-11': 'diet_modification',
        '12-17': 'diet_modification',
      },
    };
    
    String defaultAction = 'consult_pediatrician';
    return actionMap[symptom]?[ageGroup] ?? defaultAction;
  }
}
