import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class DiseasesSymptomsService {
  static final DiseasesSymptomsService _instance = DiseasesSymptomsService._internal();
  factory DiseasesSymptomsService() => _instance;
  DiseasesSymptomsService._internal();

  final Logger _logger = Logger();
  static const String _baseUrl = 'http://localhost:5000'; // Update with your model endpoint

  /// Predict disease based on symptoms
  Future<Map<String, dynamic>> predictDisease(List<String> symptoms) async {
    try {
      _logger.i('Predicting disease for symptoms: $symptoms');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'symptoms': symptoms,
          'model_type': 'diseases_symptoms'
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _logger.i('Disease prediction successful: $result');
        return result;
      } else {
        _logger.e('Failed to get prediction: ${response.statusCode}');
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error predicting disease: $e');
      throw Exception('Error predicting disease: $e');
    }
  }

  /// Get common symptoms from the dataset
  List<String> getCommonSymptoms() {
    return [
      'fever',
      'cough',
      'headache',
      'fatigue',
      'nausea',
      'vomiting',
      'diarrhea',
      'abdominal pain',
      'sore throat',
      'runny nose',
      'chills',
      'body aches',
      'loss of appetite',
      'dizziness',
      'chest pain',
      'shortness of breath',
      'wheezing',
      'rashes',
      'swelling',
      'joint pain'
    ];
  }

  /// Get disease-treatment mappings
  Map<String, String> getDiseaseTreatments() {
    return {
      'viral fever': 'Rest, fluids, acetaminophen, monitor temperature',
      'common cold': 'Rest, fluids, over-the-counter medications, nasal decongestants',
      'stomach flu': 'Rest, fluids, bland diet, anti-nausea medications',
      'migraine': 'Pain relievers, rest in dark room, avoid triggers',
      'pneumonia': 'Antibiotics, rest, fluids, oxygen therapy if needed',
      'asthma': 'Inhalers, avoid triggers, regular check-ups',
      'allergies': 'Antihistamines, avoid allergens, nasal sprays',
      'ear infection': 'Antibiotics, pain relievers, warm compress',
      'strep throat': 'Antibiotics, rest, fluids, throat lozenges',
      'bronchitis': 'Rest, fluids, cough suppressants, humidifier'
    };
  }

  /// Get pediatric-specific symptoms
  List<String> getPediatricSymptoms() {
    return [
      'fever above 100.4°F',
      'persistent crying',
      'refusing to eat or drink',
      'unusual sleepiness',
      'difficulty breathing',
      'blue lips or face',
      'severe headache',
      'stiff neck',
      'unusual rash',
      'seizures',
      'dehydration signs',
      'severe abdominal pain',
      'blood in stool or urine',
      'unusual behavior changes'
    ];
  }

  /// Get emergency symptoms that require immediate medical attention
  List<String> getEmergencySymptoms() {
    return [
      'difficulty breathing',
      'blue lips or face',
      'severe chest pain',
      'seizures',
      'unconsciousness',
      'severe bleeding',
      'head injury with confusion',
      'severe allergic reaction',
      'poisoning',
      'high fever with stiff neck'
    ];
  }

  /// Analyze symptoms and provide recommendations
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
        'timestamp': DateTime.now().toIso8601String()
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
      final treatments = getDiseaseTreatments();
      
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

  /// Get symptom severity levels
  Map<String, String> getSymptomSeverityLevels() {
    return {
      'fever': 'Monitor temperature, seek care if >104°F or persistent',
      'cough': 'Monitor frequency, seek care if severe or persistent',
      'headache': 'Monitor intensity, seek care if severe or with other symptoms',
      'fatigue': 'Normal with illness, seek care if extreme or persistent',
      'nausea': 'Monitor hydration, seek care if severe or persistent',
      'vomiting': 'Monitor hydration, seek care if severe or persistent',
      'diarrhea': 'Monitor hydration, seek care if severe or persistent',
      'abdominal pain': 'Monitor location and intensity, seek care if severe',
      'sore throat': 'Monitor swallowing, seek care if severe or persistent',
      'runny nose': 'Usually mild, seek care if severe or persistent'
    };
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing DiseasesSymptomsService...');
      // Add any initialization logic here
      _logger.i('DiseasesSymptomsService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing DiseasesSymptomsService: $e');
      throw Exception('Error initializing DiseasesSymptomsService: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _logger.i('Disposing DiseasesSymptomsService...');
    // Add any cleanup logic here
  }
} 