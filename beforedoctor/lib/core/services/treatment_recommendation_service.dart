import 'dart:convert';
import 'package:flutter/services.dart';

class TreatmentRecommendationService {
  // Age-specific medication dosages and safety guidelines
  final Map<String, Map<String, dynamic>> _ageMedicationGuidelines = {
    'infant': {
      'acetaminophen': {
        'dosage': '10-15 mg/kg every 4-6 hours',
        'max_daily': '75 mg/kg/day',
        'safety_notes': 'Do not use for children under 3 months without doctor approval',
        'forms': ['drops', 'suspension'],
      },
      'ibuprofen': {
        'dosage': '5-10 mg/kg every 6-8 hours',
        'max_daily': '40 mg/kg/day',
        'safety_notes': 'Not recommended for children under 6 months',
        'forms': ['drops', 'suspension'],
      },
      'pedialyte': {
        'dosage': '1-2 oz every 15-30 minutes',
        'max_daily': 'As needed for hydration',
        'safety_notes': 'Safe for all ages, preferred over sports drinks',
        'forms': ['liquid', 'freezer_pops'],
      },
    },
    'toddler': {
      'acetaminophen': {
        'dosage': '10-15 mg/kg every 4-6 hours',
        'max_daily': '75 mg/kg/day',
        'safety_notes': 'Use weight-based dosing, not age-based',
        'forms': ['suspension', 'chewable'],
      },
      'ibuprofen': {
        'dosage': '5-10 mg/kg every 6-8 hours',
        'max_daily': '40 mg/kg/day',
        'safety_notes': 'Take with food to prevent stomach upset',
        'forms': ['suspension', 'chewable'],
      },
      'benadryl': {
        'dosage': '1.25 mg/kg every 6 hours',
        'max_daily': '6 doses per day',
        'safety_notes': 'May cause drowsiness, monitor for side effects',
        'forms': ['liquid', 'chewable'],
      },
    },
    'child': {
      'acetaminophen': {
        'dosage': '10-15 mg/kg every 4-6 hours',
        'max_daily': '75 mg/kg/day',
        'safety_notes': 'Check for other medications containing acetaminophen',
        'forms': ['suspension', 'chewable', 'tablets'],
      },
      'ibuprofen': {
        'dosage': '5-10 mg/kg every 6-8 hours',
        'max_daily': '40 mg/kg/day',
        'safety_notes': 'Take with food, avoid if child has stomach issues',
        'forms': ['suspension', 'chewable', 'tablets'],
      },
      'benadryl': {
        'dosage': '1.25 mg/kg every 6 hours',
        'max_daily': '6 doses per day',
        'safety_notes': 'May cause drowsiness, avoid before activities',
        'forms': ['liquid', 'chewable', 'tablets'],
      },
    },
  };

  // Condition-specific treatment protocols
  final Map<String, Map<String, dynamic>> _conditionTreatments = {
    'fever': {
      'immediate_actions': [
        'Remove excess clothing',
        'Offer cool fluids',
        'Use lukewarm sponge bath if temperature > 104°F',
        'Monitor for signs of serious illness',
      ],
      'medications': ['acetaminophen', 'ibuprofen'],
      'when_to_seek_care': [
        'Temperature > 104°F (40°C)',
        'Fever lasting > 3 days',
        'Child appears very ill',
        'Fever with rash',
        'Age < 3 months with any fever',
      ],
      'home_care': [
        'Rest and fluids',
        'Light clothing',
        'Monitor temperature every 4 hours',
        'Keep child comfortable',
      ],
    },
    'cough': {
      'immediate_actions': [
        'Increase humidity in room',
        'Offer honey (for children > 1 year)',
        'Elevate head during sleep',
        'Encourage fluids',
      ],
      'medications': ['honey', 'humidifier'],
      'when_to_seek_care': [
        'Difficulty breathing',
        'Cough lasting > 2 weeks',
        'Cough with fever > 101°F',
        'Cough with chest pain',
        'Wheezing or stridor',
      ],
      'home_care': [
        'Honey (1 tsp for children > 1 year)',
        'Warm fluids',
        'Humidifier in bedroom',
        'Avoid cough suppressants in young children',
      ],
    },
    'vomiting': {
      'immediate_actions': [
        'Start with small sips of clear fluids',
        'Wait 15-30 minutes between sips',
        'Gradually increase fluid intake',
        'Monitor for signs of dehydration',
      ],
      'medications': ['pedialyte', 'oral_rehydration_solution'],
      'when_to_seek_care': [
        'Unable to keep fluids down for > 8 hours',
        'Signs of dehydration',
        'Blood in vomit',
        'Severe abdominal pain',
        'Vomiting with fever > 102°F',
      ],
      'home_care': [
        'Clear fluids only for first 2 hours',
        'Gradual return to normal diet',
        'Avoid dairy and fatty foods initially',
        'Rest and monitor closely',
      ],
    },
    'diarrhea': {
      'immediate_actions': [
        'Continue breastfeeding/formula',
        'Offer oral rehydration solution',
        'Monitor for dehydration signs',
        'Continue normal diet if tolerated',
      ],
      'medications': ['oral_rehydration_solution', 'probiotics'],
      'when_to_seek_care': [
        'Signs of dehydration',
        'Blood in stool',
        'Diarrhea lasting > 1 week',
        'Severe abdominal pain',
        'High fever with diarrhea',
      ],
      'home_care': [
        'Continue normal diet',
        'Offer extra fluids',
        'Monitor diaper output',
        'Good hand hygiene',
      ],
    },
    'rash': {
      'immediate_actions': [
        'Keep area clean and dry',
        'Avoid scratching',
        'Use gentle soap',
        'Apply cool compress if itchy',
      ],
      'medications': ['calamine_lotion', 'hydrocortisone_cream'],
      'when_to_seek_care': [
        'Rash with fever',
        'Rash spreading rapidly',
        'Blisters or open sores',
        'Rash with difficulty breathing',
        'Rash with joint pain',
      ],
      'home_care': [
        'Keep area clean',
        'Avoid irritants',
        'Use gentle moisturizer',
        'Monitor for changes',
      ],
    },
    'ear_pain': {
      'immediate_actions': [
        'Apply warm compress to ear',
        'Keep child upright',
        'Offer pain medication',
        'Monitor for fever',
      ],
      'medications': ['acetaminophen', 'ibuprofen'],
      'when_to_seek_care': [
        'Severe ear pain',
        'Ear pain with fever',
        'Drainage from ear',
        'Ear pain lasting > 24 hours',
        'Child pulling at ear constantly',
      ],
      'home_care': [
        'Pain medication as needed',
        'Warm compress',
        'Keep ear dry',
        'Monitor for fever',
      ],
    },
  };

  // Emergency protocols
  final Map<String, Map<String, dynamic>> _emergencyProtocols = {
    'difficulty_breathing': {
      'immediate_actions': [
        'Call emergency services immediately',
        'Keep child calm and upright',
        'Remove any tight clothing',
        'Do not give anything by mouth',
      ],
      'signs_to_watch': [
        'Rapid breathing',
        'Retractions (sucking in between ribs)',
        'Blue lips or face',
        'Unable to speak or cry',
        'Wheezing or stridor',
      ],
      'emergency_contact': '911',
    },
    'severe_allergic_reaction': {
      'immediate_actions': [
        'Call emergency services immediately',
        'Use epinephrine auto-injector if prescribed',
        'Keep child lying down with legs elevated',
        'Loosen tight clothing',
      ],
      'signs_to_watch': [
        'Swelling of face, lips, tongue',
        'Difficulty breathing',
        'Hives or rash',
        'Dizziness or fainting',
        'Nausea or vomiting',
      ],
      'emergency_contact': '911',
    },
    'high_fever_with_stiff_neck': {
      'immediate_actions': [
        'Call emergency services immediately',
        'Do not give medication',
        'Keep child comfortable',
        'Monitor breathing',
      ],
      'signs_to_watch': [
        'Stiff neck',
        'Severe headache',
        'Sensitivity to light',
        'Confusion or lethargy',
        'Rash that doesn\'t fade with pressure',
      ],
      'emergency_contact': '911',
    },
  };

  /// Generate comprehensive treatment recommendations
  Future<TreatmentRecommendation> generateRecommendations({
    required List<String> symptoms,
    required String childAge,
    required String childGender,
    required double severityScore,
    List<String>? emergencyFlags,
    String? temperature,
    String? duration,
  }) async {
    try {
      final ageGroup = _determineAgeGroup(childAge);
      final treatments = <TreatmentProtocol>[];
      final medications = <MedicationRecommendation>[];
      final homeCare = <String>[];
      final whenToSeekCare = <String>[];

      // Generate symptom-specific treatments
      for (final symptom in symptoms) {
        final treatment = _getSymptomTreatment(symptom, ageGroup);
        if (treatment != null) {
          treatments.add(treatment);
        }
      }

      // Generate medication recommendations
      for (final symptom in symptoms) {
        final meds = _getMedicationRecommendations(symptom, ageGroup, childAge);
        medications.addAll(meds);
      }

      // Generate home care instructions
      for (final symptom in symptoms) {
        final care = _getHomeCareInstructions(symptom, ageGroup);
        homeCare.addAll(care);
      }

      // Generate when to seek care criteria
      for (final symptom in symptoms) {
        final criteria = _getSeekCareCriteria(symptom, ageGroup);
        whenToSeekCare.addAll(criteria);
      }

      // Add emergency protocols if needed
      if (emergencyFlags != null && emergencyFlags.isNotEmpty) {
        for (final flag in emergencyFlags) {
          final emergency = _getEmergencyProtocol(flag);
          if (emergency != null) {
            treatments.add(emergency);
          }
        }
      }

      // Add severity-based recommendations
      final severityRecommendations = _getSeverityBasedRecommendations(
        severityScore,
        ageGroup,
        temperature,
        duration,
      );

      return TreatmentRecommendation(
        treatments: treatments,
        medications: medications,
        homeCare: homeCare,
        whenToSeekCare: whenToSeekCare,
        severityRecommendations: severityRecommendations,
        ageGroup: ageGroup,
        childAge: childAge,
        childGender: childGender,
        severityScore: severityScore,
        emergencyFlags: emergencyFlags ?? [],
        temperature: temperature,
        duration: duration,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to generate treatment recommendations: $e');
    }
  }

  /// Get symptom-specific treatment protocol
  TreatmentProtocol? _getSymptomTreatment(String symptom, String ageGroup) {
    final condition = _mapSymptomToCondition(symptom);
    if (condition == null || !_conditionTreatments.containsKey(condition)) {
      return null;
    }

    final treatment = _conditionTreatments[condition]!;
    return TreatmentProtocol(
      condition: condition,
      immediateActions: List<String>.from(treatment['immediate_actions'] ?? []),
      medications: List<String>.from(treatment['medications'] ?? []),
      whenToSeekCare: List<String>.from(treatment['when_to_seek_care'] ?? []),
      homeCare: List<String>.from(treatment['home_care'] ?? []),
      ageGroup: ageGroup,
    );
  }

  /// Get medication recommendations for a symptom
  List<MedicationRecommendation> _getMedicationRecommendations(
    String symptom,
    String ageGroup,
    String childAge,
  ) {
    final recommendations = <MedicationRecommendation>[];
    final condition = _mapSymptomToCondition(symptom);
    
    if (condition == null) return recommendations;

    final treatment = _conditionTreatments[condition];
    if (treatment == null) return recommendations;

    final medications = List<String>.from(treatment['medications'] ?? []);
    
    for (final medication in medications) {
      final guidelines = _ageMedicationGuidelines[ageGroup]?[medication];
      if (guidelines != null) {
        recommendations.add(MedicationRecommendation(
          name: medication,
          dosage: guidelines['dosage'] ?? '',
          maxDaily: guidelines['max_daily'] ?? '',
          safetyNotes: guidelines['safety_notes'] ?? '',
          forms: List<String>.from(guidelines['forms'] ?? []),
          ageGroup: ageGroup,
          childAge: childAge,
        ));
      }
    }

    return recommendations;
  }

  /// Get home care instructions for a symptom
  List<String> _getHomeCareInstructions(String symptom, String ageGroup) {
    final condition = _mapSymptomToCondition(symptom);
    if (condition == null || !_conditionTreatments.containsKey(condition)) {
      return [];
    }

    final treatment = _conditionTreatments[condition]!;
    return List<String>.from(treatment['home_care'] ?? []);
  }

  /// Get when to seek care criteria for a symptom
  List<String> _getSeekCareCriteria(String symptom, String ageGroup) {
    final condition = _mapSymptomToCondition(symptom);
    if (condition == null || !_conditionTreatments.containsKey(condition)) {
      return [];
    }

    final treatment = _conditionTreatments[condition]!;
    return List<String>.from(treatment['when_to_seek_care'] ?? []);
  }

  /// Get emergency protocol
  TreatmentProtocol? _getEmergencyProtocol(String emergencyFlag) {
    if (!_emergencyProtocols.containsKey(emergencyFlag)) {
      return null;
    }

    final protocol = _emergencyProtocols[emergencyFlag]!;
    return TreatmentProtocol(
      condition: emergencyFlag,
      immediateActions: List<String>.from(protocol['immediate_actions'] ?? []),
      medications: [],
      whenToSeekCare: List<String>.from(protocol['signs_to_watch'] ?? []),
      homeCare: [],
      ageGroup: 'all',
      isEmergency: true,
      emergencyContact: protocol['emergency_contact'] ?? '911',
    );
  }

  /// Get severity-based recommendations
  Map<String, dynamic> _getSeverityBasedRecommendations(
    double severityScore,
    String ageGroup,
    String? temperature,
    String? duration,
  ) {
    final recommendations = <String, dynamic>{};

    if (severityScore >= 8.0) {
      recommendations['urgency'] = 'immediate';
      recommendations['action'] = 'Seek emergency care immediately';
      recommendations['monitoring'] = 'Continuous monitoring required';
    } else if (severityScore >= 6.0) {
      recommendations['urgency'] = 'urgent';
      recommendations['action'] = 'Contact pediatrician within 24 hours';
      recommendations['monitoring'] = 'Monitor every 2-4 hours';
    } else if (severityScore >= 4.0) {
      recommendations['urgency'] = 'moderate';
      recommendations['action'] = 'Monitor closely, contact doctor if worsening';
      recommendations['monitoring'] = 'Monitor every 4-6 hours';
    } else {
      recommendations['urgency'] = 'mild';
      recommendations['action'] = 'Continue home care, contact doctor if no improvement in 48 hours';
      recommendations['monitoring'] = 'Monitor daily';
    }

    // Add temperature-specific recommendations
    if (temperature != null) {
      final temp = double.tryParse(temperature) ?? 0;
      if (temp >= 104) {
        recommendations['temperature_action'] = 'Seek immediate medical attention';
      } else if (temp >= 102) {
        recommendations['temperature_action'] = 'Contact pediatrician today';
      } else if (temp >= 100.4) {
        recommendations['temperature_action'] = 'Monitor and treat with medication as needed';
      }
    }

    // Add duration-specific recommendations
    if (duration != null) {
      if (duration.contains('week')) {
        recommendations['duration_action'] = 'Contact pediatrician for persistent symptoms';
      } else if (duration.contains('day') && !duration.contains('today')) {
        recommendations['duration_action'] = 'Monitor for improvement';
      }
    }

    return recommendations;
  }

  /// Map symptom to condition for treatment lookup
  String? _mapSymptomToCondition(String symptom) {
    final mapping = {
      'fever': 'fever',
      'temp': 'fever',
      'temperature': 'fever',
      'cough': 'cough',
      'coughing': 'cough',
      'vomiting': 'vomiting',
      'throw up': 'vomiting',
      'diarrhea': 'diarrhea',
      'loose stool': 'diarrhea',
      'rash': 'rash',
      'skin rash': 'rash',
      'ear pain': 'ear_pain',
      'ear ache': 'ear_pain',
      'headache': 'headache',
      'head ache': 'headache',
    };

    return mapping[symptom.toLowerCase()];
  }

  /// Determine age group for treatment guidelines
  String _determineAgeGroup(String age) {
    final ageNum = int.tryParse(age) ?? 0;
    
    if (ageNum < 1) return 'infant';
    if (ageNum < 3) return 'toddler';
    return 'child';
  }

  /// Get dosage calculator for medications
  Map<String, dynamic> calculateDosage(String medication, String childAge, double weight) {
    final ageGroup = _determineAgeGroup(childAge);
    final guidelines = _ageMedicationGuidelines[ageGroup]?[medication];
    
    if (guidelines == null) {
      return {'error': 'No dosage guidelines available for this medication and age'};
    }

    // Calculate dosage based on weight
    final dosageRange = guidelines['dosage'] as String;
    final maxDaily = guidelines['max_daily'] as String;
    
    // Parse dosage range (e.g., "10-15 mg/kg")
    final dosageMatch = RegExp(r'(\d+)-(\d+)\s*mg/kg').firstMatch(dosageRange);
    if (dosageMatch != null) {
      final minDose = double.parse(dosageMatch.group(1)!) * weight;
      final maxDose = double.parse(dosageMatch.group(2)!) * weight;
      
      return {
        'medication': medication,
        'age_group': ageGroup,
        'weight': weight,
        'dosage_range': '${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} mg',
        'max_daily': maxDaily,
        'safety_notes': guidelines['safety_notes'],
        'forms': guidelines['forms'],
      };
    }

    return {'error': 'Unable to calculate dosage'};
  }

  /// Get all available medications for an age group
  List<String> getAvailableMedications(String ageGroup) {
    return _ageMedicationGuidelines[ageGroup]?.keys.toList() ?? [];
  }

  /// Get all available conditions
  List<String> getAvailableConditions() {
    return _conditionTreatments.keys.toList();
  }

  /// Validate medication safety for age
  bool isMedicationSafe(String medication, String childAge) {
    final ageGroup = _determineAgeGroup(childAge);
    final guidelines = _ageMedicationGuidelines[ageGroup]?[medication];
    
    if (guidelines == null) return false;
    
    final safetyNotes = guidelines['safety_notes'] as String?;
    if (safetyNotes == null) return true;
    
    // Check for age restrictions in safety notes
    if (safetyNotes.contains('under 3 months') && int.parse(childAge) < 3) {
      return false;
    }
    if (safetyNotes.contains('under 6 months') && int.parse(childAge) < 6) {
      return false;
    }
    
    return true;
  }
}

/// Data classes for treatment recommendations
class TreatmentRecommendation {
  final List<TreatmentProtocol> treatments;
  final List<MedicationRecommendation> medications;
  final List<String> homeCare;
  final List<String> whenToSeekCare;
  final Map<String, dynamic> severityRecommendations;
  final String ageGroup;
  final String childAge;
  final String childGender;
  final double severityScore;
  final List<String> emergencyFlags;
  final String? temperature;
  final String? duration;
  final DateTime timestamp;

  TreatmentRecommendation({
    required this.treatments,
    required this.medications,
    required this.homeCare,
    required this.whenToSeekCare,
    required this.severityRecommendations,
    required this.ageGroup,
    required this.childAge,
    required this.childGender,
    required this.severityScore,
    required this.emergencyFlags,
    this.temperature,
    this.duration,
    required this.timestamp,
  });
}

class TreatmentProtocol {
  final String condition;
  final List<String> immediateActions;
  final List<String> medications;
  final List<String> whenToSeekCare;
  final List<String> homeCare;
  final String ageGroup;
  final bool isEmergency;
  final String? emergencyContact;

  TreatmentProtocol({
    required this.condition,
    required this.immediateActions,
    required this.medications,
    required this.whenToSeekCare,
    required this.homeCare,
    required this.ageGroup,
    this.isEmergency = false,
    this.emergencyContact,
  });
}

class MedicationRecommendation {
  final String name;
  final String dosage;
  final String maxDaily;
  final String safetyNotes;
  final List<String> forms;
  final String ageGroup;
  final String childAge;

  MedicationRecommendation({
    required this.name,
    required this.dosage,
    required this.maxDaily,
    required this.safetyNotes,
    required this.forms,
    required this.ageGroup,
    required this.childAge,
  });
} 