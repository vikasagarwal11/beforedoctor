import 'package:logger/logger.dart';

class ClinicalDecisionSupport {
  static final ClinicalDecisionSupport _instance = ClinicalDecisionSupport._internal();
  factory ClinicalDecisionSupport() => _instance;
  ClinicalDecisionSupport._internal();

  final Logger _logger = Logger();

  /// Clinical guidelines and decision trees
  final Map<String, Map<String, dynamic>> _clinicalGuidelines = {
    'fever': {
      'age_thresholds': {
        '0-3_months': {
          'threshold': 100.4,
          'action': 'Immediate medical evaluation required',
          'urgency': 'emergency',
          'reason': 'Infants under 3 months with fever require immediate evaluation'
        },
        '3-6_months': {
          'threshold': 102.0,
          'action': 'Medical evaluation within 24 hours',
          'urgency': 'high',
          'reason': 'Young infants with high fever need prompt evaluation'
        },
        '6_months_plus': {
          'threshold': 104.0,
          'action': 'Seek medical attention',
          'urgency': 'moderate',
          'reason': 'High fever in older children'
        }
      },
      'duration_guidelines': {
        'less_than_3_days': 'Monitor, supportive care',
        '3-5_days': 'Medical evaluation recommended',
        'more_than_5_days': 'Medical evaluation required'
      }
    },
    'respiratory_distress': {
      'emergency_signs': [
        'difficulty breathing',
        'blue lips',
        'retractions',
        'rapid breathing',
        'wheezing'
      ],
      'action': 'Immediate medical attention',
      'urgency': 'emergency',
      'reason': 'Respiratory distress is a medical emergency'
    },
    'dehydration': {
      'signs': [
        'dry mouth',
        'sunken eyes',
        'decreased urination',
        'lethargy',
        'no tears when crying'
      ],
      'action': 'Seek medical attention',
      'urgency': 'high',
      'reason': 'Dehydration can be life-threatening in children'
    },
    'head_injury': {
      'warning_signs': [
        'loss of consciousness',
        'confusion',
        'severe headache',
        'vomiting',
        'seizures'
      ],
      'action': 'Immediate medical evaluation',
      'urgency': 'emergency',
      'reason': 'Head injuries can be serious'
    }
  };

  /// Evidence-based treatment recommendations
  final Map<String, Map<String, dynamic>> _treatmentGuidelines = {
    'viral_fever': {
      'medications': {
        'acetaminophen': {
          'dosage': '10-15 mg/kg every 4-6 hours',
          'max_daily': '75 mg/kg/day',
          'age_restrictions': 'Safe for all ages',
          'contraindications': ['liver disease', 'allergy']
        },
        'ibuprofen': {
          'dosage': '10 mg/kg every 6-8 hours',
          'max_daily': '40 mg/kg/day',
          'age_restrictions': '6 months and older',
          'contraindications': ['kidney disease', 'allergy', 'stomach ulcers']
        }
      },
      'supportive_care': [
        'Rest and hydration',
        'Light clothing',
        'Cool compress',
        'Monitor temperature'
      ],
      'when_to_seek_care': [
        'Fever >104°F',
        'Fever lasting >3 days',
        'Associated severe symptoms',
        'Age <3 months with any fever'
      ]
    },
    'cough': {
      'medications': {
        'honey': {
          'dosage': '1/2 to 1 teaspoon as needed',
          'age_restrictions': '1 year and older',
          'contraindications': ['diabetes', 'allergy']
        },
        'cough_suppressant': {
          'dosage': 'As directed by healthcare provider',
          'age_restrictions': '4 years and older',
          'contraindications': ['respiratory depression']
        }
      },
      'supportive_care': [
        'Humidifier',
        'Hydration',
        'Rest',
        'Avoid irritants'
      ],
      'when_to_seek_care': [
        'Severe or persistent cough',
        'Difficulty breathing',
        'Cough with fever',
        'Cough lasting >2 weeks'
      ]
    }
  };

  /// Generate clinical decision support
  Map<String, dynamic> generateClinicalDecision(
    List<String> symptoms,
    Map<String, dynamic> childMetadata,
    Map<String, dynamic> severityAssessment
  ) {
    try {
      final age = int.tryParse(childMetadata['child_age'] ?? '0') ?? 0;
      final decisions = <String, dynamic>{};
      
      // Apply clinical guidelines
      for (String symptom in symptoms) {
        final guideline = _getClinicalGuideline(symptom, age);
        if (guideline != null) {
          decisions[symptom] = guideline;
        }
      }
      
      // Generate treatment recommendations
      final treatments = _generateTreatmentRecommendations(symptoms, age);
      
      // Assess urgency and next steps
      final urgencyAssessment = _assessUrgency(decisions, severityAssessment);
      
      return {
        'clinical_decisions': decisions,
        'treatment_recommendations': treatments,
        'urgency_assessment': urgencyAssessment,
        'next_steps': _generateNextSteps(urgencyAssessment, decisions),
        'clinical_evidence': _getClinicalEvidence(symptoms),
        'age_specific_concerns': _getAgeSpecificConcerns(age, symptoms)
      };
      
    } catch (e) {
      _logger.e('Error generating clinical decision: $e');
      throw Exception('Error generating clinical decision: $e');
    }
  }

  /// Get clinical guideline for specific symptom and age
  Map<String, dynamic>? _getClinicalGuideline(String symptom, int age) {
    final lowerSymptom = symptom.toLowerCase();
    
    // Fever guidelines
    if (lowerSymptom.contains('fever')) {
      return _getFeverGuideline(age);
    }
    
    // Respiratory guidelines
    if (lowerSymptom.contains('breathing') || lowerSymptom.contains('cough')) {
      return _getRespiratoryGuideline();
    }
    
    // Dehydration guidelines
    if (lowerSymptom.contains('vomiting') || lowerSymptom.contains('diarrhea')) {
      return _getDehydrationGuideline();
    }
    
    // Head injury guidelines
    if (lowerSymptom.contains('head') && lowerSymptom.contains('injury')) {
      return _getHeadInjuryGuideline();
    }
    
    return null;
  }

  /// Get fever-specific clinical guideline
  Map<String, dynamic> _getFeverGuideline(int age) {
    if (age < 3) {
      return {
        'guideline': 'Infant fever protocol',
        'threshold': 100.4,
        'action': 'Immediate medical evaluation required',
        'urgency': 'emergency',
        'reason': 'Infants under 3 months with fever require immediate evaluation',
        'evidence_level': 'A',
        'source': 'AAP Clinical Practice Guidelines'
      };
    } else if (age < 6) {
      return {
        'guideline': 'Young child fever protocol',
        'threshold': 102.0,
        'action': 'Medical evaluation within 24 hours',
        'urgency': 'high',
        'reason': 'Young children with high fever need prompt evaluation',
        'evidence_level': 'B',
        'source': 'AAP Clinical Practice Guidelines'
      };
    } else {
      return {
        'guideline': 'Older child fever protocol',
        'threshold': 104.0,
        'action': 'Seek medical attention if persistent',
        'urgency': 'moderate',
        'reason': 'High fever in older children',
        'evidence_level': 'C',
        'source': 'AAP Clinical Practice Guidelines'
      };
    }
  }

  /// Get respiratory-specific clinical guideline
  Map<String, dynamic> _getRespiratoryGuideline() {
    return {
      'guideline': 'Respiratory distress protocol',
      'emergency_signs': [
        'difficulty breathing',
        'blue lips',
        'retractions',
        'rapid breathing',
        'wheezing'
      ],
      'action': 'Immediate medical attention',
      'urgency': 'emergency',
      'reason': 'Respiratory distress is a medical emergency',
      'evidence_level': 'A',
      'source': 'Emergency Medicine Guidelines'
    };
  }

  /// Get dehydration-specific clinical guideline
  Map<String, dynamic> _getDehydrationGuideline() {
    return {
      'guideline': 'Dehydration assessment protocol',
      'signs': [
        'dry mouth',
        'sunken eyes',
        'decreased urination',
        'lethargy',
        'no tears when crying'
      ],
      'action': 'Seek medical attention',
      'urgency': 'high',
      'reason': 'Dehydration can be life-threatening in children',
      'evidence_level': 'A',
      'source': 'WHO Dehydration Guidelines'
    };
  }

  /// Get head injury-specific clinical guideline
  Map<String, dynamic> _getHeadInjuryGuideline() {
    return {
      'guideline': 'Head injury assessment protocol',
      'warning_signs': [
        'loss of consciousness',
        'confusion',
        'severe headache',
        'vomiting',
        'seizures'
      ],
      'action': 'Immediate medical evaluation',
      'urgency': 'emergency',
      'reason': 'Head injuries can be serious',
      'evidence_level': 'A',
      'source': 'Pediatric Head Injury Guidelines'
    };
  }

  /// Generate treatment recommendations
  Map<String, dynamic> _generateTreatmentRecommendations(List<String> symptoms, int age) {
    final recommendations = <String, dynamic>{};
    
    for (String symptom in symptoms) {
      final lowerSymptom = symptom.toLowerCase();
      
      if (lowerSymptom.contains('fever')) {
        recommendations['fever_treatment'] = _treatmentGuidelines['viral_fever'];
      }
      
      if (lowerSymptom.contains('cough')) {
        recommendations['cough_treatment'] = _treatmentGuidelines['cough'];
      }
    }
    
    // Add age-specific considerations
    if (age < 2) {
      recommendations['age_specific'] = {
        'note': 'Young children require careful medication dosing',
        'consultation': 'Always consult healthcare provider before giving medications',
        'monitoring': 'Closer monitoring required'
      };
    }
    
    return recommendations;
  }

  /// Assess overall urgency
  Map<String, dynamic> _assessUrgency(
    Map<String, dynamic> clinicalDecisions,
    Map<String, dynamic> severityAssessment
  ) {
    String urgency = 'normal';
    String reason = 'Standard monitoring';
    
    // Check for emergency conditions
    if (clinicalDecisions.values.any((decision) => decision['urgency'] == 'emergency')) {
      urgency = 'emergency';
      reason = 'Emergency symptoms detected';
    } else if (clinicalDecisions.values.any((decision) => decision['urgency'] == 'high')) {
      urgency = 'high';
      reason = 'High-priority symptoms detected';
    } else if (severityAssessment['overall_severity']['level'] == 'severe') {
      urgency = 'high';
      reason = 'Severe symptoms detected';
    }
    
    return {
      'level': urgency,
      'reason': reason,
      'immediate_action': _getImmediateAction(urgency),
      'timeframe': _getTimeframe(urgency)
    };
  }

  /// Get immediate action based on urgency
  String _getImmediateAction(String urgency) {
    switch (urgency) {
      case 'emergency':
        return 'Seek immediate medical attention';
      case 'high':
        return 'Seek medical evaluation within 24 hours';
      case 'moderate':
        return 'Monitor closely, seek care if symptoms worsen';
      default:
        return 'Monitor symptoms, provide supportive care';
    }
  }

  /// Get timeframe for action
  String _getTimeframe(String urgency) {
    switch (urgency) {
      case 'emergency':
        return 'Immediate';
      case 'high':
        return 'Within 24 hours';
      case 'moderate':
        return 'Within 48-72 hours';
      default:
        return 'As needed';
    }
  }

  /// Generate next steps
  List<String> _generateNextSteps(Map<String, dynamic> urgencyAssessment, Map<String, dynamic> clinicalDecisions) {
    final steps = <String>[];
    
    if (urgencyAssessment['level'] == 'emergency') {
      steps.add('Call emergency services or go to nearest emergency room');
      steps.add('Do not delay seeking medical care');
      steps.add('Bring child\'s medical history if available');
    } else if (urgencyAssessment['level'] == 'high') {
      steps.add('Contact healthcare provider within 24 hours');
      steps.add('Monitor symptoms closely');
      steps.add('Keep child comfortable and hydrated');
    } else {
      steps.add('Monitor symptoms for 24-48 hours');
      steps.add('Provide supportive care');
      steps.add('Contact healthcare provider if symptoms worsen');
    }
    
    return steps;
  }

  /// Get clinical evidence for symptoms
  Map<String, dynamic> _getClinicalEvidence(List<String> symptoms) {
    return {
      'evidence_sources': [
        'American Academy of Pediatrics (AAP)',
        'World Health Organization (WHO)',
        'Centers for Disease Control (CDC)',
        'Emergency Medicine Guidelines'
      ],
      'evidence_level': 'A',
      'last_updated': '2024',
      'clinical_trials': 'Based on peer-reviewed clinical studies'
    };
  }

  /// Get age-specific clinical concerns
  List<String> _getAgeSpecificConcerns(int age, List<String> symptoms) {
    final concerns = <String>[];
    
    if (age < 3) {
      concerns.add('Higher risk of complications in infants');
      concerns.add('Limited communication of symptoms');
      concerns.add('Rapid progression of illness possible');
      concerns.add('Special medication dosing requirements');
    } else if (age < 5) {
      concerns.add('Young children require careful monitoring');
      concerns.add('May not communicate symptoms clearly');
      concerns.add('Risk of dehydration higher');
    }
    
    if (symptoms.any((s) => s.toLowerCase().contains('fever')) && age < 3) {
      concerns.add('Fever in infants under 3 months is always serious');
    }
    
    return concerns;
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing ClinicalDecisionSupport...');
      // Add any initialization logic here
      _logger.i('ClinicalDecisionSupport initialized successfully');
    } catch (e) {
      _logger.e('Error initializing ClinicalDecisionSupport: $e');
      throw Exception('Error initializing ClinicalDecisionSupport: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _logger.i('Disposing ClinicalDecisionSupport...');
    // Add any cleanup logic here
  }
} 