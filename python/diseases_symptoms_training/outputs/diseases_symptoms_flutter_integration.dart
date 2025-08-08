
// Diseases_Symptoms Model Integration for Flutter
// Generated on: 2025-08-07T02:36:44.286209

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DiseasesSymptomsModel {
  static const String _modelUrl = 'YOUR_MODEL_ENDPOINT';
  
  static Future<Map<String, dynamic>> predictDisease(List<String> symptoms) async {
    try {
      final response = await http.post(
        Uri.parse('$_modelUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'symptoms': symptoms,
          'model_type': 'diseases_symptoms'
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting disease: $e');
    }
  }
  
  static Future<List<String>> getCommonSymptoms() async {
    // Return common symptoms from the dataset
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
      'runny nose'
    ];
  }
  
  static Future<Map<String, String>> getDiseaseTreatments() async {
    // Return disease-treatment mappings
    return {
      'viral fever': 'Rest, fluids, acetaminophen',
      'common cold': 'Rest, fluids, over-the-counter medications',
      'stomach flu': 'Rest, fluids, bland diet',
      'migraine': 'Pain relievers, rest in dark room',
      'pneumonia': 'Antibiotics, rest, fluids'
    };
  }
}
