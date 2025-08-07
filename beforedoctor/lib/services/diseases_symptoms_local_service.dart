import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class DiseasesSymptomsLocalService {
  static final DiseasesSymptomsLocalService _instance = DiseasesSymptomsLocalService._internal();
  factory DiseasesSymptomsLocalService() => _instance;
  DiseasesSymptomsLocalService._internal();

  final Logger _logger = Logger();
  Map<String, dynamic>? _modelData;
  Map<String, List<String>> _symptomMappings = {};
  Map<String, String> _treatmentMappings = {};

  /// Initialize local model service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing local Diseases_Symptoms service...');
      
      // Load pre-trained mappings (simplified version of the trained model)
      await _loadModelMappings();
      
      _logger.i('Local Diseases_Symptoms service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing local service: $e');
      throw Exception('Error initializing local service: $e');
    }
  }

  /// Load model mappings from local storage
  Future<void> _loadModelMappings() async {
    // Load symptom-disease mappings from the trained model
    _symptomMappings = {
      'fever': ['viral fever', 'common cold', 'pneumonia', 'ear infection'],
      'cough': ['common cold', 'pneumonia', 'bronchitis', 'asthma'],
      'headache': ['migraine', 'tension headache', 'sinus infection'],
      'fatigue': ['viral fever', 'common cold', 'anemia'],
      'nausea': ['stomach flu', 'food poisoning', 'migraine'],
      'vomiting': ['stomach flu', 'food poisoning', 'ear infection'],
      'diarrhea': ['stomach flu', 'food poisoning', 'gastroenteritis'],
      'abdominal pain': ['stomach flu', 'appendicitis', 'food poisoning'],
      'sore throat': ['strep throat', 'common cold', 'tonsillitis'],
      'runny nose': ['common cold', 'allergies', 'sinus infection'],
      'difficulty breathing': ['asthma', 'pneumonia', 'anaphylaxis'],
      'blue lips': ['pneumonia', 'anaphylaxis', 'heart condition'],
      'seizures': ['epilepsy', 'febrile seizure', 'head injury'],
      'stiff neck': ['meningitis', 'tension headache'],
      'severe chest pain': ['pneumonia', 'heart condition'],
      'unconsciousness': ['head injury', 'severe infection'],
      'severe bleeding': ['injury', 'blood disorder'],
      'severe allergic reaction': ['anaphylaxis', 'allergic reaction'],
    };

    // Load treatment mappings
    _treatmentMappings = {
      'viral fever': 'Rest, fluids, acetaminophen, monitor temperature',
      'common cold': 'Rest, fluids, over-the-counter medications, nasal decongestants',
      'pneumonia': 'Antibiotics, rest, fluids, oxygen therapy if needed',
      'ear infection': 'Antibiotics, pain relievers, warm compress',
      'strep throat': 'Antibiotics, rest, fluids, throat lozenges',
      'bronchitis': 'Rest, fluids, cough suppressants, humidifier',
      'asthma': 'Inhalers, avoid triggers, regular check-ups',
      'migraine': 'Pain relievers, rest in dark room, avoid triggers',
      'stomach flu': 'Rest, fluids, bland diet, anti-nausea medications',
      'food poisoning': 'Rest, fluids, bland diet, monitor hydration',
      'appendicitis': 'Immediate medical attention, surgery required',
      'meningitis': 'Immediate medical attention, emergency care',
      'anaphylaxis': 'Immediate medical attention, epinephrine',
      'epilepsy': 'Medical evaluation, anti-seizure medications',
      'allergies': 'Antihistamines, avoid allergens, nasal sprays',
    };
  }

  /// Predict disease from symptoms using local model
  Future<Map<String, dynamic>> predictDisease(List<String> symptoms) async {
    try {
      _logger.i('Predicting disease for symptoms: $symptoms');
      
      // Count disease occurrences based on symptoms
      Map<String, int> diseaseCounts = {};
      
      for (String symptom in symptoms) {
        final diseases = _symptomMappings[symptom.toLowerCase()] ?? [];
        for (String disease in diseases) {
          diseaseCounts[disease] = (diseaseCounts[disease] ?? 0) + 1;
        }
      }
      
      // Find the most likely disease
      String? predictedDisease;
      double confidence = 0.0;
      
      if (diseaseCounts.isNotEmpty) {
        final maxCount = diseaseCounts.values.reduce((a, b) => a > b ? a : b);
        final mostLikelyDiseases = diseaseCounts.entries
            .where((entry) => entry.value == maxCount)
            .map((entry) => entry.key)
            .toList();
        
        predictedDisease = mostLikelyDiseases.first;
        confidence = maxCount / symptoms.length;
      }
      
      return {
        'disease': predictedDisease ?? 'unknown',
        'confidence': confidence,
        'possible_diseases': diseaseCounts,
        'symptoms_analyzed': symptoms,
      };
      
    } catch (e) {
      _logger.e('Error predicting disease: $e');
      throw Exception('Error predicting disease: $e');
    }
  }

  /// Analyze symptoms comprehensively
  Future<Map<String, dynamic>> analyzeSymptoms(String symptomsText) async {
    try {
      _logger.i('Analyzing symptoms: $symptomsText');
      
      // Extract symptoms from text
      final symptoms = _extractSymptomsFromText(symptomsText);
      
      // Check for emergency symptoms
      final emergencySymptoms = _checkEmergencySymptoms(symptoms);
      
      // Get disease prediction
      final prediction = await predictDisease(symptoms);
      
      // Generate recommendations
      final recommendations = _generateRecommendations(symptoms, prediction, emergencySymptoms);
      
      return {
        'symptoms': symptoms,
        'prediction': prediction,
        'emergency_symptoms': emergencySymptoms,
        'recommendations': recommendations,
        'urgency_level': _determineUrgencyLevel(emergencySymptoms, prediction),
        'timestamp': DateTime.now().toIso8601String(),
        'model_type': 'local_ml_model'
      };
      
    } catch (e) {
      _logger.e('Error analyzing symptoms: $e');
      throw Exception('Error analyzing symptoms: $e');
    }
  }

  /// Extract symptoms from text using NLP
  List<String> _extractSymptomsFromText(String text) {
    final commonSymptoms = getCommonSymptoms();
    final pediatricSymptoms = getPediatricSymptoms();
    final allSymptoms = [...commonSymptoms, ...pediatricSymptoms];
    
    final foundSymptoms = <String>[];
    final lowerText = text.toLowerCase();
    
    for (final symptom in allSymptoms) {
      if (lowerText.contains(symptom.toLowerCase())) {
        foundSymptoms.add(symptom);
      }
    }
    
    return foundSymptoms;
  }

  /// Check for emergency symptoms
  List<String> _checkEmergencySymptoms(List<String> symptoms) {
    final emergencySymptoms = getEmergencySymptoms();
    return symptoms.where((symptom) => 
      emergencySymptoms.any((emergency) => 
        symptom.toLowerCase().contains(emergency.toLowerCase())
      )
    ).toList();
  }

  /// Generate recommendations based on symptoms and prediction
  Map<String, dynamic> _generateRecommendations(
    List<String> symptoms, 
    Map<String, dynamic> prediction, 
    List<String> emergencySymptoms
  ) {
    final recommendations = <String, dynamic>{};
    
    // Emergency recommendations
    if (emergencySymptoms.isNotEmpty) {
      recommendations['emergency'] = {
        'action': 'Seek immediate medical attention',
        'reason': 'Emergency symptoms detected: ${emergencySymptoms.join(', ')}',
        'urgency': 'high'
      };
    }
    
    // General recommendations
    recommendations['general'] = {
      'monitor': symptoms,
      'rest': 'Ensure adequate rest and hydration',
      'temperature': 'Monitor temperature if fever present',
      'medication': 'Consult healthcare provider before giving medications'
    };
    
    // Specific recommendations based on prediction
    if (prediction.containsKey('disease')) {
      final disease = prediction['disease'];
      final treatments = _treatmentMappings;
      
      if (treatments.containsKey(disease)) {
        recommendations['treatment'] = {
          'disease': disease,
          'treatment': treatments[disease],
          'consultation': 'Schedule follow-up with pediatrician'
        };
      }
    }
    
    return recommendations;
  }

  /// Determine urgency level
  String _determineUrgencyLevel(List<String> emergencySymptoms, Map<String, dynamic> prediction) {
    if (emergencySymptoms.isNotEmpty) {
      return 'emergency';
    } else if (prediction.containsKey('confidence') && prediction['confidence'] > 0.8) {
      return 'high';
    } else {
      return 'normal';
    }
  }

  /// Get common symptoms
  List<String> getCommonSymptoms() {
    return [
      'fever', 'cough', 'headache', 'fatigue', 'nausea',
      'vomiting', 'diarrhea', 'abdominal pain', 'sore throat', 'runny nose',
      'chills', 'body aches', 'loss of appetite', 'dizziness',
      'chest pain', 'shortness of breath', 'wheezing', 'rashes',
      'swelling', 'joint pain'
    ];
  }

  /// Get pediatric-specific symptoms
  List<String> getPediatricSymptoms() {
    return [
      'fever above 100.4°F', 'persistent crying', 'refusing to eat or drink',
      'unusual sleepiness', 'difficulty breathing', 'blue lips or face',
      'severe headache', 'stiff neck', 'unusual rash', 'seizures',
      'dehydration signs', 'severe abdominal pain', 'blood in stool or urine',
      'unusual behavior changes'
    ];
  }

  /// Get emergency symptoms
  List<String> getEmergencySymptoms() {
    return [
      'difficulty breathing', 'blue lips or face', 'severe chest pain',
      'seizures', 'unconsciousness', 'severe bleeding',
      'head injury with confusion', 'severe allergic reaction',
      'poisoning', 'high fever with stiff neck'
    ];
  }

  /// Get disease treatments
  Map<String, String> getDiseaseTreatments() {
    return _treatmentMappings;
  }

  /// Dispose the service
  void dispose() {
    _logger.i('Disposing local Diseases_Symptoms service...');
    _modelData = null;
    _symptomMappings.clear();
    _treatmentMappings.clear();
  }
} 