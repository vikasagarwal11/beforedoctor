import 'package:logger/logger.dart';

class SymptomSeverityAssessor {
  static final SymptomSeverityAssessor _instance = SymptomSeverityAssessor._internal();
  factory SymptomSeverityAssessor() => _instance;
  SymptomSeverityAssessor._internal();

  final Logger _logger = Logger();

  /// Assess symptom severity based on age and symptoms
  Map<String, dynamic> assessSeverity(List<String> symptoms, Map<String, dynamic> childMetadata) {
    try {
      final age = int.tryParse(childMetadata['child_age'] ?? '0') ?? 0;
      final severityScores = <String, Map<String, dynamic>>{};
      
      for (String symptom in symptoms) {
        severityScores[symptom] = _calculateSymptomSeverity(symptom, age);
      }
      
      final overallSeverity = _calculateOverallSeverity(severityScores);
      final recommendations = _generateSeverityRecommendations(severityScores, overallSeverity, age);
      
      return {
        'symptom_severities': severityScores,
        'overall_severity': overallSeverity,
        'age_specific_concerns': _getAgeSpecificConcerns(age, symptoms),
        'recommendations': recommendations,
        'monitoring_guidelines': _getMonitoringGuidelines(severityScores, age),
      };
      
    } catch (e) {
      _logger.e('Error assessing symptom severity: $e');
      throw Exception('Error assessing symptom severity: $e');
    }
  }

  /// Calculate severity for individual symptom
  Map<String, dynamic> _calculateSymptomSeverity(String symptom, int age) {
    final lowerSymptom = symptom.toLowerCase();
    
    // Base severity levels
    final severityLevels = {
      'fever': _assessFeverSeverity(lowerSymptom, age),
      'cough': _assessCoughSeverity(lowerSymptom, age),
      'headache': _assessHeadacheSeverity(lowerSymptom, age),
      'fatigue': _assessFatigueSeverity(lowerSymptom, age),
      'nausea': _assessNauseaSeverity(lowerSymptom, age),
      'vomiting': _assessVomitingSeverity(lowerSymptom, age),
      'diarrhea': _assessDiarrheaSeverity(lowerSymptom, age),
      'abdominal pain': _assessAbdominalPainSeverity(lowerSymptom, age),
      'sore throat': _assessSoreThroatSeverity(lowerSymptom, age),
      'runny nose': _assessRunnyNoseSeverity(lowerSymptom, age),
      'difficulty breathing': _assessBreathingSeverity(lowerSymptom, age),
      'blue lips': _assessBlueLipsSeverity(lowerSymptom, age),
      'seizures': _assessSeizureSeverity(lowerSymptom, age),
      'stiff neck': _assessStiffNeckSeverity(lowerSymptom, age),
    };
    
    return severityLevels[symptom] ?? _getDefaultSeverity(symptom);
  }

  /// Assess fever severity with age-specific considerations
  Map<String, dynamic> _assessFeverSeverity(String symptom, int age) {
    if (!symptom.contains('fever')) return _getDefaultSeverity('fever');
    
    // Extract temperature if mentioned
    double? temperature;
    if (symptom.contains('102') || symptom.contains('103')) {
      temperature = 102.0;
    } else if (symptom.contains('104') || symptom.contains('105')) {
      temperature = 104.0;
    } else if (symptom.contains('100') || symptom.contains('101')) {
      temperature = 100.0;
    }
    
    if (temperature == null) {
      return {
        'level': 'moderate',
        'score': 6,
        'description': 'Fever present - monitor temperature',
        'action': 'Monitor temperature, seek care if >104°F or persistent',
        'age_concerns': age < 3 ? 'Higher risk in infants' : 'Standard monitoring'
      };
    }
    
    if (temperature >= 104) {
      return {
        'level': 'severe',
        'score': 9,
        'description': 'High fever - immediate attention needed',
        'action': 'Seek immediate medical attention',
        'age_concerns': age < 3 ? 'Critical in infants' : 'Emergency care needed'
      };
    } else if (temperature >= 102) {
      return {
        'level': 'moderate',
        'score': 7,
        'description': 'Moderate fever - monitor closely',
        'action': 'Monitor temperature, seek care if persistent >3 days',
        'age_concerns': age < 3 ? 'Higher risk in infants' : 'Standard monitoring'
      };
    } else {
      return {
        'level': 'mild',
        'score': 4,
        'description': 'Low-grade fever - monitor',
        'action': 'Monitor temperature, rest, fluids',
        'age_concerns': age < 3 ? 'Monitor closely in infants' : 'Standard care'
      };
    }
  }

  /// Assess cough severity
  Map<String, dynamic> _assessCoughSeverity(String symptom, int age) {
    if (!symptom.contains('cough')) return _getDefaultSeverity('cough');
    
    if (symptom.contains('severe') || symptom.contains('persistent')) {
      return {
        'level': 'severe',
        'score': 8,
        'description': 'Severe or persistent cough',
        'action': 'Seek medical evaluation',
        'age_concerns': age < 2 ? 'Higher risk in young children' : 'Standard evaluation'
      };
    } else if (symptom.contains('dry') || symptom.contains('productive')) {
      return {
        'level': 'moderate',
        'score': 6,
        'description': 'Moderate cough',
        'action': 'Monitor frequency, seek care if severe or persistent',
        'age_concerns': age < 2 ? 'Monitor closely' : 'Standard monitoring'
      };
    } else {
      return {
        'level': 'mild',
        'score': 3,
        'description': 'Mild cough',
        'action': 'Monitor, rest, fluids',
        'age_concerns': 'Standard care'
      };
    }
  }

  /// Assess breathing difficulty severity
  Map<String, dynamic> _assessBreathingSeverity(String symptom, int age) {
    if (!symptom.contains('difficulty breathing') && !symptom.contains('shortness of breath')) {
      return _getDefaultSeverity('difficulty breathing');
    }
    
    return {
      'level': 'severe',
      'score': 10,
      'description': 'Difficulty breathing - emergency',
      'action': 'Seek immediate medical attention',
      'age_concerns': age < 2 ? 'Critical emergency in infants' : 'Emergency care needed'
    };
  }

  /// Assess seizure severity
  Map<String, dynamic> _assessSeizureSeverity(String symptom, int age) {
    if (!symptom.contains('seizure')) return _getDefaultSeverity('seizures');
    
    return {
      'level': 'severe',
      'score': 10,
      'description': 'Seizure - emergency',
      'action': 'Seek immediate medical attention',
      'age_concerns': age < 5 ? 'Critical in young children' : 'Emergency care needed'
    };
  }

  /// Assess abdominal pain severity
  Map<String, dynamic> _assessAbdominalPainSeverity(String symptom, int age) {
    if (!symptom.contains('abdominal pain') && !symptom.contains('stomach pain')) {
      return _getDefaultSeverity('abdominal pain');
    }
    
    if (symptom.contains('severe')) {
      return {
        'level': 'severe',
        'score': 9,
        'description': 'Severe abdominal pain',
        'action': 'Seek immediate medical attention',
        'age_concerns': age < 5 ? 'Higher risk in young children' : 'Emergency evaluation needed'
      };
    } else {
      return {
        'level': 'moderate',
        'score': 6,
        'description': 'Moderate abdominal pain',
        'action': 'Monitor location and intensity, seek care if severe',
        'age_concerns': age < 5 ? 'Monitor closely' : 'Standard monitoring'
      };
    }
  }

  /// Get default severity for unknown symptoms
  Map<String, dynamic> _getDefaultSeverity(String symptom) {
    return {
      'level': 'unknown',
      'score': 5,
      'description': 'Symptom detected - monitor',
      'action': 'Monitor symptoms, seek care if severe',
      'age_concerns': 'Standard monitoring'
    };
  }

  /// Calculate overall severity from individual symptoms
  Map<String, dynamic> _calculateOverallSeverity(Map<String, Map<String, dynamic>> symptomSeverities) {
    if (symptomSeverities.isEmpty) {
      return {
        'level': 'unknown',
        'score': 0,
        'description': 'No symptoms assessed'
      };
    }
    
    final scores = symptomSeverities.values.map((s) => s['score'] as int).toList();
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    
    String level;
    if (maxScore >= 9) {
      level = 'severe';
    } else if (maxScore >= 6) {
      level = 'moderate';
    } else {
      level = 'mild';
    }
    
    return {
      'level': level,
      'score': maxScore,
      'average_score': avgScore,
      'description': _getOverallSeverityDescription(level, maxScore),
      'symptom_count': symptomSeverities.length
    };
  }

  /// Get description for overall severity
  String _getOverallSeverityDescription(String level, int score) {
    switch (level) {
      case 'severe':
        return 'Severe symptoms requiring immediate medical attention';
      case 'moderate':
        return 'Moderate symptoms requiring medical evaluation';
      case 'mild':
        return 'Mild symptoms - monitor and provide supportive care';
      default:
        return 'Unknown severity - monitor symptoms';
    }
  }

  /// Generate severity-based recommendations
  Map<String, dynamic> _generateSeverityRecommendations(
    Map<String, Map<String, dynamic>> symptomSeverities,
    Map<String, dynamic> overallSeverity,
    int age
  ) {
    final recommendations = <String, dynamic>{};
    
    // Emergency recommendations
    if (overallSeverity['level'] == 'severe') {
      recommendations['emergency'] = {
        'action': 'Seek immediate medical attention',
        'reason': 'Severe symptoms detected',
        'urgency': 'high'
      };
    }
    
    // Age-specific recommendations
    if (age < 3) {
      recommendations['age_specific'] = {
        'action': 'Closer monitoring required for infants',
        'reason': 'Higher risk in children under 3',
        'monitoring_frequency': 'Every 2-4 hours'
      };
    } else if (age < 5) {
      recommendations['age_specific'] = {
        'action': 'Monitor closely',
        'reason': 'Young children require careful observation',
        'monitoring_frequency': 'Every 4-6 hours'
      };
    }
    
    // Symptom-specific recommendations
    final severeSymptoms = symptomSeverities.entries
        .where((entry) => entry.value['level'] == 'severe')
        .map((entry) => entry.key)
        .toList();
    
    if (severeSymptoms.isNotEmpty) {
      recommendations['severe_symptoms'] = {
        'symptoms': severeSymptoms,
        'action': 'Immediate medical evaluation required',
        'priority': 'high'
      };
    }
    
    return recommendations;
  }

  /// Get age-specific concerns
  List<String> _getAgeSpecificConcerns(int age, List<String> symptoms) {
    final concerns = <String>[];
    
    if (age < 3) {
      concerns.add('Higher risk of complications in infants');
      concerns.add('Dehydration risk increased');
      concerns.add('Fever above 100.4°F requires medical attention');
    } else if (age < 5) {
      concerns.add('Young children require careful monitoring');
      concerns.add('Risk of rapid symptom progression');
    }
    
    if (symptoms.any((s) => s.toLowerCase().contains('fever'))) {
      if (age < 3) {
        concerns.add('Fever in infants under 3 months is always serious');
      }
    }
    
    if (symptoms.any((s) => s.toLowerCase().contains('seizure'))) {
      concerns.add('Seizures in children require immediate medical attention');
    }
    
    return concerns;
  }

  /// Get monitoring guidelines
  Map<String, dynamic> _getMonitoringGuidelines(Map<String, Map<String, dynamic>> symptomSeverities, int age) {
    final guidelines = <String, dynamic>{};
    
    // Temperature monitoring
    if (symptomSeverities.keys.any((s) => s.toLowerCase().contains('fever'))) {
      guidelines['temperature'] = {
        'frequency': age < 3 ? 'Every 2 hours' : 'Every 4 hours',
        'threshold': age < 3 ? '100.4°F' : '102°F',
        'action_above_threshold': 'Seek medical attention'
      };
    }
    
    // Hydration monitoring
    if (symptomSeverities.keys.any((s) => s.toLowerCase().contains('vomiting') || s.toLowerCase().contains('diarrhea'))) {
      guidelines['hydration'] = {
        'frequency': 'Every 1-2 hours',
        'signs_of_dehydration': ['dry mouth', 'sunken eyes', 'decreased urination'],
        'action_if_dehydrated': 'Seek medical attention'
      };
    }
    
    // Breathing monitoring
    if (symptomSeverities.keys.any((s) => s.toLowerCase().contains('breathing'))) {
      guidelines['breathing'] = {
        'frequency': 'Continuous monitoring',
        'warning_signs': ['rapid breathing', 'retractions', 'blue lips'],
        'action_if_worsening': 'Seek immediate medical attention'
      };
    }
    
    return guidelines;
  }

  /// Assess other symptom severities (placeholder implementations)
  Map<String, dynamic> _assessHeadacheSeverity(String symptom, int age) => _getDefaultSeverity('headache');
  Map<String, dynamic> _assessFatigueSeverity(String symptom, int age) => _getDefaultSeverity('fatigue');
  Map<String, dynamic> _assessNauseaSeverity(String symptom, int age) => _getDefaultSeverity('nausea');
  Map<String, dynamic> _assessVomitingSeverity(String symptom, int age) => _getDefaultSeverity('vomiting');
  Map<String, dynamic> _assessDiarrheaSeverity(String symptom, int age) => _getDefaultSeverity('diarrhea');
  Map<String, dynamic> _assessSoreThroatSeverity(String symptom, int age) => _getDefaultSeverity('sore throat');
  Map<String, dynamic> _assessRunnyNoseSeverity(String symptom, int age) => _getDefaultSeverity('runny nose');
  Map<String, dynamic> _assessBlueLipsSeverity(String symptom, int age) => _getDefaultSeverity('blue lips');
  Map<String, dynamic> _assessStiffNeckSeverity(String symptom, int age) => _getDefaultSeverity('stiff neck');
} 