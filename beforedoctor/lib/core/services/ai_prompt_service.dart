import 'dart:convert';
import 'package:flutter/services.dart';
import '../../services/data_loader_service.dart';

class AIPromptService {
  final Map<String, dynamic> _templates = {};

  Future<void> loadTemplates() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/pediatric_llm_prompt_templates_full.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      _templates.clear();
      _templates.addAll(data);
    } catch (e) {
      // Fallback to built-in templates if JSON file is not available
      _loadBuiltInTemplates();
    }
  }

  /// Load built-in templates as fallback
  void _loadBuiltInTemplates() {
    _templates.clear();
    _templates.addAll({
      'fever': {
        'prompt_template': '''
You are a board-certified pediatrician. A parent reports their {{child_age}}-year-old {{gender}} child has a fever.

**Symptom Details:**
- Temperature: {{temperature}}
- Duration: {{duration}}
- Associated symptoms: {{associated_symptoms}}
- Medications given: {{medications}}

**Please provide:**
1. **Assessment**: Most likely cause and severity
2. **Immediate Actions**: What the parent should do now
3. **Medications**: Age-appropriate dosing recommendations
4. **Red Flags**: When to seek immediate medical care
5. **Follow-up**: When to contact doctor

**Important**: Include age-appropriate considerations and safety disclaimers.
''',
        'follow_up_questions': [
          'How high did the fever get?',
          'How was the temperature measured?',
          'Any other symptoms (cough, rash, vomiting)?',
          'Has the child been around sick people?',
          'Any recent travel or exposure?'
        ]
      },
      'cough': {
        'prompt_template': '''
You are a board-certified pediatrician. A parent reports their {{child_age}}-year-old {{gender}} child has a cough.

**Symptom Details:**
- Cough type: {{cough_type}}
- Duration: {{duration}}
- Timing: {{timing}}
- Associated symptoms: {{associated_symptoms}}

**Please provide:**
1. **Assessment**: Most likely cause and severity
2. **Comfort Measures**: How to help the child feel better
3. **Medications**: Age-appropriate recommendations
4. **Red Flags**: When to seek immediate medical care
5. **Follow-up**: When to contact doctor

**Important**: Include age-appropriate considerations and safety disclaimers.
''',
        'follow_up_questions': [
          'Is it a dry or wet cough?',
          'When is it worse (night, activity)?',
          'Any fever or breathing difficulty?',
          'Any recent cold or exposure?',
          'Any wheezing or chest pain?'
        ]
      },
      'vomiting': {
        'prompt_template': '''
You are a board-certified pediatrician. A parent reports their {{child_age}}-year-old {{gender}} child is vomiting.

**Symptom Details:**
- Frequency: {{frequency}}
- Duration: {{duration}}
- Content: {{content}}
- Associated symptoms: {{associated_symptoms}}

**Please provide:**
1. **Assessment**: Most likely cause and severity
2. **Hydration**: How to prevent dehydration
3. **Diet**: What to feed/avoid
4. **Red Flags**: When to seek immediate medical care
5. **Follow-up**: When to contact doctor

**Important**: Include age-appropriate considerations and safety disclaimers.
''',
        'follow_up_questions': [
          'How many times has the child vomited?',
          'What did they eat before vomiting?',
          'Any fever or diarrhea?',
          'Any recent head injury?',
          'Signs of dehydration (dry mouth, no tears)?'
        ]
      },
      'diarrhea': {
        'prompt_template': '''
You are a board-certified pediatrician. A parent reports their {{child_age}}-year-old {{gender}} child has diarrhea.

**Symptom Details:**
- Frequency: {{frequency}}
- Duration: {{duration}}
- Consistency: {{consistency}}
- Associated symptoms: {{associated_symptoms}}

**Please provide:**
1. **Assessment**: Most likely cause and severity
2. **Hydration**: How to prevent dehydration
3. **Diet**: What to feed/avoid
4. **Red Flags**: When to seek immediate medical care
5. **Follow-up**: When to contact doctor

**Important**: Include age-appropriate considerations and safety disclaimers.
''',
        'follow_up_questions': [
          'How many episodes per day?',
          'What does the stool look like?',
          'Any blood or mucus?',
          'Any fever or vomiting?',
          'Signs of dehydration?'
        ]
      },
      'ear_pain': {
        'prompt_template': '''
You are a board-certified pediatrician. A parent reports their {{child_age}}-year-old {{gender}} child has ear pain.

**Symptom Details:**
- Location: {{location}}
- Duration: {{duration}}
- Severity: {{severity}}
- Associated symptoms: {{associated_symptoms}}

**Please provide:**
1. **Assessment**: Most likely cause and severity
2. **Pain Relief**: Age-appropriate pain management
3. **Medications**: Recommendations if needed
4. **Red Flags**: When to seek immediate medical care
5. **Follow-up**: When to contact doctor

**Important**: Include age-appropriate considerations and safety disclaimers.
''',
        'follow_up_questions': [
          'Which ear is affected?',
          'Is the child pulling at their ear?',
          'Any fever or cold symptoms?',
          'Any fluid draining from ear?',
          'Any recent swimming or water exposure?'
        ]
      },
      'rash': {
        'prompt_template': '''
You are a board-certified pediatrician. A parent reports their {{child_age}}-year-old {{gender}} child has a rash.

**Symptom Details:**
- Location: {{location}}
- Appearance: {{appearance}}
- Duration: {{duration}}
- Associated symptoms: {{associated_symptoms}}

**Please provide:**
1. **Assessment**: Most likely cause and severity
2. **Comfort Measures**: How to help with itching/pain
3. **Medications**: Topical treatments if appropriate
4. **Red Flags**: When to seek immediate medical care
5. **Follow-up**: When to contact doctor

**Important**: Include age-appropriate considerations and safety disclaimers.
''',
        'follow_up_questions': [
          'Where is the rash located?',
          'What does it look like (red, bumpy, blisters)?',
          'Is it itchy or painful?',
          'Any fever or other symptoms?',
          'Any recent exposure to new foods, soaps, or medications?'
        ]
      }
    });
  }

  /// Given a symptom like 'fever', return the structured prompt template
  Map<String, dynamic>? getPromptForSymptom(String symptom) {
    return _templates[symptom.toLowerCase()];
  }

  /// Get all supported symptoms
  List<String> getSupportedSymptoms() {
    return _templates.keys.toList();
  }

  /// Construct the dynamic LLM prompt by injecting the child metadata
  String buildLLMPrompt(String symptom, Map<String, String> childMetadata) {
    final template = getPromptForSymptom(symptom);
    if (template == null) return '';

    String prompt = template['prompt_template'];
    childMetadata.forEach((key, value) {
      prompt = prompt.replaceAll('{{$key}}', value);
    });

    return prompt;
  }

  /// Get follow-up questions for a symptom
  List<String> getFollowUpQuestions(String symptom) {
    final template = getPromptForSymptom(symptom);
    if (template == null) return [];
    
    return List<String>.from(template['follow_up_questions'] ?? []);
  }

  /// Check if a symptom is supported
  bool isSymptomSupported(String symptom) {
    return _templates.containsKey(symptom.toLowerCase());
  }

  /// Get all available prompt templates
  Map<String, dynamic> getAllTemplates() {
    return Map.from(_templates);
  }

  /// Add a custom template (for future extensibility)
  void addCustomTemplate(String symptom, Map<String, dynamic> template) {
    _templates[symptom.toLowerCase()] = template;
  }

  /// ENHANCED: Get treatment suggestions from real-world dataset
  Future<Map<String, dynamic>?> getTreatmentSuggestion(String symptom, String ageGroup) async {
    try {
      final treatment = await DataLoaderService.getTreatmentForSymptom(symptom, ageGroup);
      if (treatment != null) {
        print('🏥 Found treatment suggestion for $symptom in $ageGroup');
        return treatment;
      }
    } catch (e) {
      print('❌ Error getting treatment suggestion: $e');
    }
    return null;
  }

  /// ENHANCED: Get follow-up questions from real-world dataset
  Future<List<String>> getEnhancedFollowUpQuestions(String symptom) async {
    try {
      final questions = await DataLoaderService.getFollowUpQuestions(symptom);
      if (questions.isNotEmpty) {
        print('❓ Found ${questions.length} follow-up questions for $symptom');
        return questions;
      }
    } catch (e) {
      print('❌ Error getting enhanced follow-up questions: $e');
    }
    
    // Fallback to built-in questions
    return getFollowUpQuestions(symptom);
  }

  /// ENHANCED: Get red flags from real-world dataset
  Future<List<String>> getRedFlags(String symptom) async {
    try {
      final redFlags = await DataLoaderService.getRedFlags(symptom);
      if (redFlags.isNotEmpty) {
        print('🚨 Found ${redFlags.length} red flags for $symptom');
        return redFlags;
      }
    } catch (e) {
      print('❌ Error getting red flags: $e');
    }
    return [];
  }

  /// ENHANCED: Build comprehensive prompt with real-world data
  Future<String> buildEnhancedLLMPrompt(String symptom, Map<String, String> childMetadata) async {
    String prompt = buildLLMPrompt(symptom, childMetadata);
    if (prompt.isEmpty) return '';

    try {
      final ageGroup = _determineAgeGroup(childMetadata['child_age'] ?? '');
      final treatment = await getTreatmentSuggestion(symptom, ageGroup);

      if (treatment != null) {
        prompt += '\n\n**EVIDENCE-BASED TREATMENT SUGGESTIONS:**\n';
        final medications = treatment['treatment']?['medications'] as List<dynamic>?;
        if (medications != null && medications.isNotEmpty) {
          prompt += '\n**Medications:**\n';
          for (final med in medications) {
            prompt += '- ${med['name']} (${med['type']}): ${med['dosage']}\n';
            if (med['note'] != null) {
              prompt += '  Note: ${med['note']}\n';
            }
          }
        }
        final homeCare = treatment['treatment']?['home_care'] as List<dynamic>?;
        if (homeCare != null && homeCare.isNotEmpty) {
          prompt += '\n**Home Care:**\n';
          for (final care in homeCare) {
            prompt += '- $care\n';
          }
        }
        final redFlags = treatment['treatment']?['red_flags'] as List<dynamic>?;
        if (redFlags != null && redFlags.isNotEmpty) {
          prompt += '\n**Red Flags (Seek Immediate Care):**\n';
          for (final flag in redFlags) {
            prompt += '- $flag\n';
          }
        }
      }

      // Add comprehensive child health information for better recommendations
      prompt += '\n\n**CHILD HEALTH PROFILE FOR ENHANCED RECOMMENDATIONS:**\n';
      
      // Basic demographics
      prompt += '- Age: ${childMetadata['child_age']} years (${ageGroup})\n';
      prompt += '- Gender: ${childMetadata['child_gender']}\n';
      
      // Vital measurements
      if (childMetadata['child_weight_kg']?.isNotEmpty == true) {
        prompt += '- Weight: ${childMetadata['child_weight_kg']} kg\n';
      }
      if (childMetadata['child_height_cm']?.isNotEmpty == true) {
        prompt += '- Height: ${childMetadata['child_height_cm']} cm\n';
      }
      if (childMetadata['child_bmi']?.isNotEmpty == true) {
        prompt += '- BMI: ${childMetadata['child_bmi']}\n';
      }
      
      // Medical information
      if (childMetadata['child_allergies']?.isNotEmpty == true && 
          childMetadata['child_allergies'] != 'None') {
        prompt += '- ⚠️ ALLERGIES: ${childMetadata['child_allergies']}\n';
      }
      if (childMetadata['child_medications']?.isNotEmpty == true) {
        prompt += '- Current Medications: ${childMetadata['child_medications']}\n';
      }
      if (childMetadata['child_medical_history']?.isNotEmpty == true) {
        prompt += '- Medical History: ${childMetadata['child_medical_history']}\n';
      }
      if (childMetadata['child_blood_type']?.isNotEmpty == true) {
        prompt += '- Blood Type: ${childMetadata['child_blood_type']}\n';
      }
      
      // Immunization and development
      if (childMetadata['child_immunization_status']?.isNotEmpty == true) {
        prompt += '- Immunization Status: ${childMetadata['child_immunization_status']}\n';
      }
      if (childMetadata['child_developmental_milestones']?.isNotEmpty == true) {
        prompt += '- Developmental Status: ${childMetadata['child_developmental_milestones']}\n';
      }
      
      // Lifestyle factors
      if (childMetadata['child_activity_level']?.isNotEmpty == true) {
        prompt += '- Activity Level: ${childMetadata['child_activity_level']}\n';
      }
      if (childMetadata['child_dietary_restrictions']?.isNotEmpty == true && 
          childMetadata['child_dietary_restrictions'] != 'None') {
        prompt += '- Dietary Restrictions: ${childMetadata['child_dietary_restrictions']}\n';
      }

      // Emergency information
      if (childMetadata['child_emergency_contact']?.isNotEmpty == true) {
        prompt += '- Emergency Contact: ${childMetadata['child_emergency_contact']}\n';
      }
      if (childMetadata['child_pediatrician']?.isNotEmpty == true) {
        prompt += '- Pediatrician: ${childMetadata['child_pediatrician']}\n';
      }

      prompt += '\n\n**SPECIAL CONSIDERATIONS:**\n';
      
      // Weight-based dosing considerations
      if (childMetadata['child_weight_kg']?.isNotEmpty == true) {
        prompt += '- Provide weight-based dosing recommendations when applicable\n';
        prompt += '- Consider age-appropriate medication forms (liquid vs tablet)\n';
      }
      
      // Allergy considerations
      if (childMetadata['child_allergies']?.isNotEmpty == true && 
          childMetadata['child_allergies'] != 'None') {
        prompt += '- ⚠️ AVOID medications containing: ${childMetadata['child_allergies']}\n';
        prompt += '- Suggest alternative treatments if needed\n';
      }
      
      // Medical history considerations
      if (childMetadata['child_medical_history']?.isNotEmpty == true) {
        prompt += '- Consider existing conditions in treatment recommendations\n';
        prompt += '- Monitor for interactions with current medications\n';
      }
      
      // Development considerations
      if (childMetadata['child_developmental_milestones'] != 'Normal') {
        prompt += '- Consider developmental status in treatment approach\n';
        prompt += '- Adjust communication and care instructions accordingly\n';
      }

      prompt += '\n\n**RECOMMENDATION GUIDELINES:**\n';
      prompt += '- Provide age-appropriate treatment options\n';
      prompt += '- Include dosage calculations based on weight when applicable\n';
      prompt += '- Suggest monitoring parameters specific to the child\'s age and condition\n';
      prompt += '- Recommend appropriate follow-up timing\n';
      prompt += '- Include emergency warning signs to watch for\n';
      prompt += '- Consider the child\'s activity level and dietary restrictions in recommendations\n';

    } catch (e) {
      print('❌ Error building enhanced prompt: $e');
    }

    return prompt;
  }

  /// Helper method to determine age group from age string
  String _determineAgeGroup(String ageStr) {
    try {
      final age = int.tryParse(ageStr) ?? 0;
      if (age < 1) return '0-3 months';
      if (age < 3) return '1-3 years';
      if (age < 6) return '3-6 years';
      if (age < 12) return '6-12 years';
      return '12-18 years';
    } catch (e) {
      return '3-6 years'; // Default fallback
    }
  }
}

// Example usage:
// final service = AIPromptService();
// await service.loadTemplates();
// final prompt = service.buildLLMPrompt('fever', {
//   'child_age': '2', 
//   'gender': 'male',
//   'temperature': '102°F',
//   'duration': '2 days',
//   'associated_symptoms': 'cough, runny nose',
//   'medications': 'Tylenol given'
// }); 