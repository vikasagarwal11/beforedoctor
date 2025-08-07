import 'dart:convert';
import 'package:flutter/services.dart';

class DataLoaderService {
  static Map<String, dynamic>? _symptomDataset;
  static List<dynamic>? _promptTree;
  
  /// Load pediatric symptom treatment dataset
  static Future<Map<String, dynamic>> loadSymptomDataset() async {
    if (_symptomDataset != null) return _symptomDataset!;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/pediatric_symptom_treatment_dataset.json');
      _symptomDataset = jsonDecode(jsonString) as Map<String, dynamic>;
      print('✅ Loaded pediatric symptom treatment dataset');
      return _symptomDataset!;
    } catch (e) {
      print('❌ Error loading symptom dataset: $e');
      // Return empty dataset if file doesn't exist yet
      return {};
    }
  }
  
  /// Load prompt logic tree for follow-up questions
  static Future<List<dynamic>> loadPromptTree() async {
    if (_promptTree != null) return _promptTree!;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/prompt_logic_tree.json');
      _promptTree = jsonDecode(jsonString) as List<dynamic>;
      print('✅ Loaded prompt logic tree');
      return _promptTree!;
    } catch (e) {
      print('❌ Error loading prompt tree: $e');
      // Return empty list if file doesn't exist yet
      return [];
    }
  }
  
  /// Get age-specific treatment for a symptom
  static Future<Map<String, dynamic>?> getTreatmentForSymptom(String symptom, String ageGroup) async {
    final dataset = await loadSymptomDataset();
    if (dataset.isEmpty) return null;
    
    try {
      final List<dynamic> records = dataset['records'] ?? [];
      for (final record in records) {
        if (record['symptom']?.toString().toLowerCase() == symptom.toLowerCase()) {
          final ageGroups = record['age_groups'] as Map<String, dynamic>?;
          if (ageGroups != null && ageGroups.containsKey(ageGroup)) {
            return ageGroups[ageGroup] as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      print('❌ Error getting treatment for $symptom: $e');
    }
    return null;
  }
  
  /// Get follow-up questions for a symptom
  static Future<List<String>> getFollowUpQuestions(String symptom) async {
    final promptTree = await loadPromptTree();
    if (promptTree.isEmpty) return [];
    
    try {
      for (final record in promptTree) {
        if (record['symptom']?.toString().toLowerCase() == symptom.toLowerCase()) {
          final questions = record['follow_up_questions'] as List<dynamic>?;
          return questions?.cast<String>() ?? [];
        }
      }
    } catch (e) {
      print('❌ Error getting follow-up questions for $symptom: $e');
    }
    return [];
  }
  
  /// Get red flags for a symptom
  static Future<List<String>> getRedFlags(String symptom) async {
    final promptTree = await loadPromptTree();
    if (promptTree.isEmpty) return [];
    
    try {
      for (final record in promptTree) {
        if (record['symptom']?.toString().toLowerCase() == symptom.toLowerCase()) {
          final redFlags = record['red_flags_to_trigger'] as List<dynamic>?;
          return redFlags?.cast<String>() ?? [];
        }
      }
    } catch (e) {
      print('❌ Error getting red flags for $symptom: $e');
    }
    return [];
  }
  
  /// Clear cached data (for testing)
  static void clearCache() {
    _symptomDataset = null;
    _promptTree = null;
    print('🗑️ Cleared data cache');
  }
} 