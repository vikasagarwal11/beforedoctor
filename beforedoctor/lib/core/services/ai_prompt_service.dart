import 'dart:convert';
import 'package:flutter/services.dart';

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