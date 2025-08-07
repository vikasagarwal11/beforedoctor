// Disease Prediction Service for BeforeDoctor
// Generated from trained disease database models

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class DiseasePredictionService {
  static final DiseasePredictionService _instance = DiseasePredictionService._internal();
  factory DiseasePredictionService() => _instance;
  DiseasePredictionService._internal();

  List<Map<String, dynamic>> _diseases = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load disease database from assets
      final String response = await rootBundle.loadString('assets/data/pediatric_disease_database.json');
      final data = await json.decode(response);
      _diseases = List<Map<String, dynamic>>.from(data);
      _isInitialized = true;
    } catch (e) {
      print('Failed to load disease database: $e');
      // Use fallback data
      _diseases = _getFallbackDiseases();
      _isInitialized = true;
    }
  }

  List<Map<String, dynamic>> _getFallbackDiseases() {
    return [
      {
        'disease': 'Common Cold',
        'common_symptom': 'runny nose, cough, fever, sore throat',
        'treatment': 'rest, hydration, over-the-counter medications'
      },
      {
        'disease': 'Ear Infection',
        'common_symptom': 'ear pain, fever, irritability, difficulty sleeping',
        'treatment': 'antibiotics, pain relief, warm compress'
      },
      {
        'disease': 'Strep Throat',
        'common_symptom': 'sore throat, fever, difficulty swallowing, swollen lymph nodes',
        'treatment': 'antibiotics, rest, pain relief'
      },
      {
        'disease': 'Pink Eye',
        'common_symptom': 'red eyes, itching, discharge, sensitivity to light',
        'treatment': 'antibiotic eye drops, warm compress, hygiene'
      },
      {
        'disease': 'Hand Foot Mouth Disease',
        'common_symptom': 'fever, sore throat, rash on hands and feet, mouth sores',
        'treatment': 'rest, hydration, pain relief, isolation'
      }
    ];
  }

  Future<Map<String, dynamic>> predictDisease(String symptoms) async {
    await initialize();
    
    if (symptoms.trim().isEmpty) {
      return {
        'disease': 'No symptoms provided',
        'confidence': 0.0,
        'symptoms': symptoms,
        'recommendations': ['Please provide specific symptoms']
      };
    }

    // Simple keyword-based disease prediction
    final symptomsLower = symptoms.toLowerCase();
    Map<String, double> diseaseScores = {};

    for (final disease in _diseases) {
      final diseaseSymptoms = disease['common_symptom'].toString().toLowerCase();
      final diseaseName = disease['disease'].toString().toLowerCase();
      
      double score = 0.0;
      
      // Check for symptom matches
      if (symptomsLower.contains('fever') && diseaseSymptoms.contains('fever')) {
        score += 0.3;
      }
      if (symptomsLower.contains('cough') && diseaseSymptoms.contains('cough')) {
        score += 0.3;
      }
      if (symptomsLower.contains('sore throat') && diseaseSymptoms.contains('sore throat')) {
        score += 0.4;
      }
      if (symptomsLower.contains('ear pain') && diseaseSymptoms.contains('ear pain')) {
        score += 0.5;
      }
      if (symptomsLower.contains('rash') && diseaseSymptoms.contains('rash')) {
        score += 0.4;
      }
      if (symptomsLower.contains('runny nose') && diseaseSymptoms.contains('runny nose')) {
        score += 0.3;
      }
      
      if (score > 0) {
        diseaseScores[disease['disease']] = score;
      }
    }

    if (diseaseScores.isEmpty) {
      return {
        'disease': 'Unknown condition',
        'confidence': 0.1,
        'symptoms': symptoms,
        'recommendations': ['Monitor symptoms', 'Contact pediatrician if symptoms worsen']
      };
    }

    // Find the best match
    final bestMatch = diseaseScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    return {
      'disease': bestMatch.key,
      'confidence': bestMatch.value,
      'symptoms': symptoms,
      'recommendations': ['Monitor symptoms', 'Contact pediatrician if symptoms worsen', 'Follow recommended treatment']
    };
  }

  Future<List<String>> getSimilarDiseases(String query) async {
    await initialize();
    
    if (query.trim().isEmpty) return [];
    
    final queryLower = query.toLowerCase();
    List<String> similarDiseases = [];
    
    for (final disease in _diseases) {
      final diseaseName = disease['disease'].toString().toLowerCase();
      final diseaseSymptoms = disease['common_symptom'].toString().toLowerCase();
      
      if (diseaseName.contains(queryLower) || diseaseSymptoms.contains(queryLower)) {
        similarDiseases.add(disease['disease']);
      }
    }
    
    return similarDiseases.take(5).toList();
  }

  Future<Map<String, dynamic>> getTreatmentRecommendations(String disease) async {
    await initialize();
    
    if (disease.isEmpty) {
      return {
        'treatments': ['Rest', 'Hydration'],
        'medications': ['Consult pediatrician'],
        'lifestyle': ['Monitor symptoms', 'Keep child comfortable']
      };
    }

    // Find disease in database
    final diseaseLower = disease.toLowerCase();
    for (final diseaseData in _diseases) {
      if (diseaseData['disease'].toString().toLowerCase().contains(diseaseLower)) {
        final treatment = diseaseData['treatment'].toString();
        
        return {
          'treatments': _extractTreatments(treatment),
          'medications': _extractMedications(treatment),
          'lifestyle': ['Rest', 'Hydration', 'Monitor symptoms'],
          'full_treatment': treatment
        };
      }
    }
    
    // Default recommendations
    return {
      'treatments': ['Rest', 'Hydration', 'Monitor symptoms'],
      'medications': ['Consult pediatrician for medication recommendations'],
      'lifestyle': ['Keep child comfortable', 'Monitor temperature', 'Encourage fluids']
    };
  }

  List<String> _extractTreatments(String treatment) {
    final treatments = <String>[];
    
    if (treatment.toLowerCase().contains('antibiotic')) {
      treatments.add('Antibiotics');
    }
    if (treatment.toLowerCase().contains('rest')) {
      treatments.add('Rest');
    }
    if (treatment.toLowerCase().contains('hydration')) {
      treatments.add('Hydration');
    }
    if (treatment.toLowerCase().contains('pain relief')) {
      treatments.add('Pain relief');
    }
    if (treatment.toLowerCase().contains('warm compress')) {
      treatments.add('Warm compress');
    }
    
    return treatments.isNotEmpty ? treatments : ['Rest', 'Hydration'];
  }

  List<String> _extractMedications(String treatment) {
    final medications = <String>[];
    
    if (treatment.toLowerCase().contains('acetaminophen') || treatment.toLowerCase().contains('tylenol')) {
      medications.add('Acetaminophen (Tylenol)');
    }
    if (treatment.toLowerCase().contains('ibuprofen') || treatment.toLowerCase().contains('advil')) {
      medications.add('Ibuprofen (Advil)');
    }
    if (treatment.toLowerCase().contains('antibiotic')) {
      medications.add('Prescription antibiotics');
    }
    
    return medications.isNotEmpty ? medications : ['Consult pediatrician for medication recommendations'];
  }
}

class DiseaseDatabase {
  static List<Map<String, dynamic>> diseases = [];
  
  static Future<void> loadDiseases() async {
    // TODO: Load from assets
    final String response = await rootBundle.loadString('assets/data/pediatric_disease_database.json');
    final data = await json.decode(response);
    diseases = List<Map<String, dynamic>>.from(data);
  }
  
  static List<Map<String, dynamic>> searchDiseases(String query) {
    return diseases.where((disease) => 
      disease['disease'].toString().toLowerCase().contains(query.toLowerCase()) ||
      disease['common_symptom'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
