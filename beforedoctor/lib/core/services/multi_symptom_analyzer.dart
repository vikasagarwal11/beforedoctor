import 'dart:convert';
import 'package:flutter/services.dart';

class MultiSymptomAnalyzer {
  static const String _symptomCorrelationDataPath = 'assets/data/symptom_correlation_matrix.json';
  
  // Symptom correlation matrix for common pediatric conditions
  final Map<String, Map<String, double>> _symptomCorrelations = {
    'fever': {
      'cough': 0.8,
      'fatigue': 0.7,
      'headache': 0.6,
      'body_aches': 0.9,
      'chills': 0.8,
      'loss_appetite': 0.5,
    },
    'cough': {
      'fever': 0.8,
      'runny_nose': 0.9,
      'sore_throat': 0.7,
      'chest_pain': 0.6,
      'wheezing': 0.8,
      'fatigue': 0.5,
    },
    'vomiting': {
      'diarrhea': 0.9,
      'fever': 0.6,
      'abdominal_pain': 0.8,
      'nausea': 0.9,
      'dehydration': 0.7,
      'loss_appetite': 0.8,
    },
    'diarrhea': {
      'vomiting': 0.9,
      'abdominal_pain': 0.8,
      'fever': 0.5,
      'dehydration': 0.9,
      'loss_appetite': 0.7,
      'nausea': 0.6,
    },
    'rash': {
      'fever': 0.7,
      'itching': 0.9,
      'swelling': 0.6,
      'joint_pain': 0.5,
      'fatigue': 0.4,
    },
    'headache': {
      'fever': 0.6,
      'nausea': 0.5,
      'vomiting': 0.4,
      'sensitivity_light': 0.7,
      'fatigue': 0.6,
    },
  };

  // Age-specific symptom severity weights
  final Map<String, Map<String, double>> _ageSeverityWeights = {
    'infant': {
      'fever': 1.0,
      'vomiting': 1.0,
      'diarrhea': 1.0,
      'dehydration': 1.0,
      'lethargy': 1.0,
    },
    'toddler': {
      'fever': 0.9,
      'vomiting': 0.9,
      'diarrhea': 0.9,
      'dehydration': 0.9,
      'behavioral_changes': 0.8,
    },
    'child': {
      'fever': 0.8,
      'vomiting': 0.8,
      'diarrhea': 0.8,
      'dehydration': 0.8,
      'complaints': 0.7,
    },
  };

  // Condition patterns for differential diagnosis
  final Map<String, List<String>> _conditionPatterns = {
    'flu': ['fever', 'cough', 'fatigue', 'body_aches', 'headache'],
    'cold': ['cough', 'runny_nose', 'sore_throat', 'congestion'],
    'stomach_virus': ['vomiting', 'diarrhea', 'abdominal_pain', 'fever'],
    'strep_throat': ['sore_throat', 'fever', 'headache', 'loss_appetite'],
    'ear_infection': ['ear_pain', 'fever', 'irritability', 'loss_appetite'],
    'pneumonia': ['cough', 'fever', 'chest_pain', 'fatigue', 'difficulty_breathing'],
    'allergic_reaction': ['rash', 'itching', 'swelling', 'difficulty_breathing'],
    'migraine': ['headache', 'nausea', 'sensitivity_light', 'sensitivity_sound'],
    'appendicitis': ['abdominal_pain', 'nausea', 'vomiting', 'fever', 'loss_appetite'],
    'dehydration': ['dry_mouth', 'decreased_urination', 'fatigue', 'dizziness'],
  };

  // Emergency conditions that require immediate attention
  final List<String> _emergencyConditions = [
    'difficulty_breathing',
    'severe_abdominal_pain',
    'unconsciousness',
    'severe_head_injury',
    'severe_allergic_reaction',
    'high_fever_with_stiff_neck',
  ];

  /// Analyze multiple symptoms and provide comprehensive assessment
  Future<MultiSymptomAnalysis> analyzeSymptoms({
    required List<String> symptoms,
    required String childAge,
    required String childGender,
    String? temperature,
    String? duration,
  }) async {
    try {
      // Normalize symptoms
      final normalizedSymptoms = _normalizeSymptoms(symptoms);
      
      // Determine age group
      final ageGroup = _determineAgeGroup(childAge);
      
      // Calculate symptom correlations
      final correlations = _calculateSymptomCorrelations(normalizedSymptoms);
      
      // Identify potential conditions
      final conditions = _identifyPotentialConditions(normalizedSymptoms);
      
      // Calculate severity score
      final severityScore = _calculateSeverityScore(
        normalizedSymptoms,
        ageGroup,
        temperature,
        duration,
      );
      
      // Check for emergency conditions
      final emergencyFlags = _checkEmergencyConditions(normalizedSymptoms);
      
      // Generate recommendations
      final recommendations = _generateRecommendations(
        conditions,
        severityScore,
        emergencyFlags,
        ageGroup,
      );
      
      // Create follow-up questions
      final followUpQuestions = _generateFollowUpQuestions(
        normalizedSymptoms,
        conditions,
        ageGroup,
      );

      return MultiSymptomAnalysis(
        primarySymptoms: normalizedSymptoms,
        correlatedSymptoms: correlations,
        potentialConditions: conditions,
        severityScore: severityScore,
        emergencyFlags: emergencyFlags,
        recommendations: recommendations,
        followUpQuestions: followUpQuestions,
        confidence: _calculateAnalysisConfidence(normalizedSymptoms, conditions),
        ageGroup: ageGroup,
        analysisTimestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to analyze symptoms: $e');
    }
  }

  /// Normalize symptom names for consistent analysis
  List<String> _normalizeSymptoms(List<String> symptoms) {
    final normalized = <String>[];
    
    for (final symptom in symptoms) {
      final lowerSymptom = symptom.toLowerCase().trim();
      
      // Map common variations to standard terms
      final mapping = {
        'temp': 'fever',
        'high temp': 'fever',
        'throwing up': 'vomiting',
        'puke': 'vomiting',
        'poop': 'diarrhea',
        'loose stools': 'diarrhea',
        'tummy ache': 'abdominal_pain',
        'stomach ache': 'abdominal_pain',
        'belly pain': 'abdominal_pain',
        'runny nose': 'runny_nose',
        'stuffy nose': 'congestion',
        'sore throat': 'sore_throat',
        'ear ache': 'ear_pain',
        'head ache': 'headache',
        'body aches': 'body_aches',
        'muscle pain': 'body_aches',
        'tired': 'fatigue',
        'exhausted': 'fatigue',
        'lethargic': 'fatigue',
        'itchy': 'itching',
        'skin rash': 'rash',
        'hives': 'rash',
        'wheezing': 'difficulty_breathing',
        'shortness of breath': 'difficulty_breathing',
        'trouble breathing': 'difficulty_breathing',
      };
      
      final normalizedSymptom = mapping[lowerSymptom] ?? lowerSymptom;
      if (!normalized.contains(normalizedSymptom)) {
        normalized.add(normalizedSymptom);
      }
    }
    
    return normalized;
  }

  /// Determine age group for severity weighting
  String _determineAgeGroup(String age) {
    final ageNum = int.tryParse(age) ?? 0;
    
    if (ageNum < 1) return 'infant';
    if (ageNum < 3) return 'toddler';
    return 'child';
  }

  /// Calculate correlations between symptoms
  Map<String, double> _calculateSymptomCorrelations(List<String> symptoms) {
    final correlations = <String, double>{};
    
    for (final symptom in symptoms) {
      if (_symptomCorrelations.containsKey(symptom)) {
        final relatedSymptoms = _symptomCorrelations[symptom]!;
        
        for (final relatedSymptom in relatedSymptoms.keys) {
          if (!symptoms.contains(relatedSymptom)) {
            correlations[relatedSymptom] = relatedSymptoms[relatedSymptom]!;
          }
        }
      }
    }
    
    // Sort by correlation strength
    final sortedCorrelations = Map.fromEntries(
      correlations.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
    
    return sortedCorrelations;
  }

  /// Identify potential conditions based on symptom patterns
  List<ConditionMatch> _identifyPotentialConditions(List<String> symptoms) {
    final matches = <ConditionMatch>[];
    
    for (final condition in _conditionPatterns.keys) {
      final pattern = _conditionPatterns[condition]!;
      final matchingSymptoms = symptoms.where((s) => pattern.contains(s)).toList();
      
      if (matchingSymptoms.isNotEmpty) {
        final matchScore = matchingSymptoms.length / pattern.length;
        if (matchScore >= 0.3) { // At least 30% match
          matches.add(ConditionMatch(
            condition: condition,
            matchingSymptoms: matchingSymptoms,
            matchScore: matchScore,
            confidence: _calculateConditionConfidence(matchingSymptoms, pattern),
          ));
        }
      }
    }
    
    // Sort by match score
    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    
    return matches;
  }

  /// Calculate severity score based on symptoms, age, and additional factors
  double _calculateSeverityScore(
    List<String> symptoms,
    String ageGroup,
    String? temperature,
    String? duration,
  ) {
    double score = 0.0;
    
    // Base score from symptoms
    for (final symptom in symptoms) {
      final severityWeight = _ageSeverityWeights[ageGroup]?[symptom] ?? 0.5;
      score += severityWeight;
    }
    
    // Temperature factor
    if (temperature != null) {
      final temp = double.tryParse(temperature) ?? 0;
      if (temp >= 104) score += 2.0; // High fever
      else if (temp >= 102) score += 1.5; // Moderate fever
      else if (temp >= 100.4) score += 1.0; // Low fever
    }
    
    // Duration factor
    if (duration != null) {
      if (duration.contains('week')) score += 0.5;
      if (duration.contains('day') && !duration.contains('today')) score += 0.3;
    }
    
    // Emergency condition multiplier
    for (final symptom in symptoms) {
      if (_emergencyConditions.contains(symptom)) {
        score *= 2.0; // Double severity for emergency conditions
      }
    }
    
    return score.clamp(0.0, 10.0);
  }

  /// Check for emergency conditions requiring immediate attention
  List<String> _checkEmergencyConditions(List<String> symptoms) {
    return symptoms.where((symptom) => _emergencyConditions.contains(symptom)).toList();
  }

  /// Generate recommendations based on analysis
  List<Recommendation> _generateRecommendations(
    List<ConditionMatch> conditions,
    double severityScore,
    List<String> emergencyFlags,
    String ageGroup,
  ) {
    final recommendations = <Recommendation>[];
    
    // Emergency recommendations
    if (emergencyFlags.isNotEmpty) {
      recommendations.add(Recommendation(
        type: RecommendationType.emergency,
        title: '🚨 EMERGENCY: Seek Immediate Medical Attention',
        description: 'The following symptoms require immediate medical evaluation: ${emergencyFlags.join(', ')}',
        priority: Priority.critical,
        action: 'Call emergency services or go to nearest emergency room immediately.',
      ));
    }
    
    // High severity recommendations
    if (severityScore >= 7.0) {
      recommendations.add(Recommendation(
        type: RecommendationType.urgent,
        title: '⚠️ Urgent Care Recommended',
        description: 'Symptoms indicate moderate to high severity. Consider urgent care evaluation.',
        priority: Priority.high,
        action: 'Contact pediatrician or visit urgent care within 24 hours.',
      ));
    }
    
    // Condition-specific recommendations
    for (final condition in conditions.take(3)) { // Top 3 conditions
      final recommendation = _getConditionRecommendation(condition, ageGroup);
      if (recommendation != null) {
        recommendations.add(recommendation);
      }
    }
    
    // General monitoring recommendations
    if (severityScore < 5.0) {
      recommendations.add(Recommendation(
        type: RecommendationType.monitoring,
        title: '📊 Monitor Symptoms',
        description: 'Continue monitoring symptoms and watch for any changes or worsening.',
        priority: Priority.medium,
        action: 'Keep symptom diary and contact doctor if symptoms worsen or persist >48 hours.',
      ));
    }
    
    return recommendations;
  }

  /// Generate follow-up questions based on symptoms and conditions
  List<String> _generateFollowUpQuestions(
    List<String> symptoms,
    List<ConditionMatch> conditions,
    String ageGroup,
  ) {
    final questions = <String>[];
    
    // Symptom-specific questions
    if (symptoms.contains('fever')) {
      questions.add('What is the child\'s temperature?');
      questions.add('How long has the fever been present?');
      questions.add('Does the fever respond to medication?');
    }
    
    if (symptoms.contains('vomiting')) {
      questions.add('How many times has the child vomited?');
      questions.add('Is the child able to keep fluids down?');
      questions.add('What color is the vomit?');
    }
    
    if (symptoms.contains('diarrhea')) {
      questions.add('How many bowel movements today?');
      questions.add('What is the consistency of the stools?');
      questions.add('Is there blood in the stool?');
    }
    
    if (symptoms.contains('rash')) {
      questions.add('Where is the rash located?');
      questions.add('Is the rash itchy or painful?');
      questions.add('When did the rash first appear?');
    }
    
    // Age-specific questions
    if (ageGroup == 'infant') {
      questions.add('Is the child eating and drinking normally?');
      questions.add('How many wet diapers in the last 24 hours?');
      questions.add('Is the child more irritable than usual?');
    }
    
    // Condition-specific questions
    for (final condition in conditions.take(2)) {
      final conditionQuestions = _getConditionQuestions(condition.condition);
      questions.addAll(conditionQuestions);
    }
    
    return questions.take(5).toList(); // Limit to 5 questions
  }

  /// Calculate confidence in the analysis
  double _calculateAnalysisConfidence(List<String> symptoms, List<ConditionMatch> conditions) {
    double confidence = 0.0;
    
    // More symptoms = higher confidence
    confidence += (symptoms.length * 0.1).clamp(0.0, 0.3);
    
    // Strong condition matches = higher confidence
    if (conditions.isNotEmpty) {
      confidence += conditions.first.matchScore * 0.4;
    }
    
    // Symptom correlation strength
    final correlationStrength = _calculateCorrelationStrength(symptoms);
    confidence += correlationStrength * 0.3;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate correlation strength between symptoms
  double _calculateCorrelationStrength(List<String> symptoms) {
    if (symptoms.length < 2) return 0.0;
    
    double totalCorrelation = 0.0;
    int correlationCount = 0;
    
    for (int i = 0; i < symptoms.length; i++) {
      for (int j = i + 1; j < symptoms.length; j++) {
        final symptom1 = symptoms[i];
        final symptom2 = symptoms[j];
        
        if (_symptomCorrelations.containsKey(symptom1) &&
            _symptomCorrelations[symptom1]!.containsKey(symptom2)) {
          totalCorrelation += _symptomCorrelations[symptom1]![symptom2]!;
          correlationCount++;
        }
      }
    }
    
    return correlationCount > 0 ? totalCorrelation / correlationCount : 0.0;
  }

  /// Get condition-specific recommendation
  Recommendation? _getConditionRecommendation(ConditionMatch condition, String ageGroup) {
    switch (condition.condition) {
      case 'flu':
        return Recommendation(
          type: RecommendationType.treatment,
          title: '🦠 Flu Management',
          description: 'Rest, fluids, and fever management. Monitor for complications.',
          priority: Priority.medium,
          action: 'Use acetaminophen/ibuprofen for fever. Contact doctor if symptoms worsen.',
        );
      case 'stomach_virus':
        return Recommendation(
          type: RecommendationType.treatment,
          title: '🤢 Stomach Virus Care',
          description: 'Focus on hydration and electrolyte replacement.',
          priority: Priority.medium,
          action: 'Offer small sips of clear fluids. Contact doctor if unable to keep fluids down.',
        );
      case 'dehydration':
        return Recommendation(
          type: RecommendationType.urgent,
          title: '💧 Dehydration Risk',
          description: 'Signs of dehydration detected. Immediate attention needed.',
          priority: Priority.high,
          action: 'Seek medical attention immediately for rehydration.',
        );
      default:
        return null;
    }
  }

  /// Get condition-specific questions
  List<String> _getConditionQuestions(String condition) {
    switch (condition) {
      case 'flu':
        return [
          'Does the child have any underlying health conditions?',
          'Has the child received a flu vaccine this season?',
        ];
      case 'stomach_virus':
        return [
          'Has anyone else in the family been sick?',
          'What did the child eat in the last 24 hours?',
        ];
      case 'dehydration':
        return [
          'When was the child\'s last wet diaper/urination?',
          'Is the child crying with tears?',
        ];
      default:
        return [];
    }
  }

  /// Calculate condition confidence
  double _calculateConditionConfidence(List<String> matchingSymptoms, List<String> pattern) {
    final matchRatio = matchingSymptoms.length / pattern.length;
    final symptomStrength = matchingSymptoms.length / matchingSymptoms.length;
    return (matchRatio + symptomStrength) / 2;
  }
}

/// Data classes for multi-symptom analysis
class MultiSymptomAnalysis {
  final List<String> primarySymptoms;
  final Map<String, double> correlatedSymptoms;
  final List<ConditionMatch> potentialConditions;
  final double severityScore;
  final List<String> emergencyFlags;
  final List<Recommendation> recommendations;
  final List<String> followUpQuestions;
  final double confidence;
  final String ageGroup;
  final DateTime analysisTimestamp;

  MultiSymptomAnalysis({
    required this.primarySymptoms,
    required this.correlatedSymptoms,
    required this.potentialConditions,
    required this.severityScore,
    required this.emergencyFlags,
    required this.recommendations,
    required this.followUpQuestions,
    required this.confidence,
    required this.ageGroup,
    required this.analysisTimestamp,
  });
}

class ConditionMatch {
  final String condition;
  final List<String> matchingSymptoms;
  final double matchScore;
  final double confidence;

  ConditionMatch({
    required this.condition,
    required this.matchingSymptoms,
    required this.matchScore,
    required this.confidence,
  });
}

class Recommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final Priority priority;
  final String action;

  Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.action,
  });
}

enum RecommendationType {
  emergency,
  urgent,
  treatment,
  monitoring,
  prevention,
}

enum Priority {
  critical,
  high,
  medium,
  low,
} 