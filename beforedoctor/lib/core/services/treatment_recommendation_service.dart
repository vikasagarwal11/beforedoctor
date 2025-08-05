import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TreatmentRecommendationService {
  static TreatmentRecommendationService? _instance;
  static TreatmentRecommendationService get instance => _instance ??= TreatmentRecommendationService._internal();

  TreatmentRecommendationService._internal();

  final AppConfig _config = AppConfig.instance;

  // Medication database with age-appropriate dosing
  static const Map<String, Map<String, dynamic>> _medicationDatabase = {
    'acetaminophen': {
      'dosing': '10-15 mg/kg every 4-6 hours',
      'max_daily': '75 mg/kg/day',
      'age_restrictions': 'Safe from birth',
      'precautions': 'Check liver function if long-term use',
      'brand_names': ['Tylenol', 'Tempra']
    },
    'ibuprofen': {
      'dosing': '5-10 mg/kg every 6-8 hours',
      'max_daily': '40 mg/kg/day',
      'age_restrictions': '6 months and older',
      'precautions': 'Avoid if dehydrated, kidney issues',
      'brand_names': ['Motrin', 'Advil']
    },
    'amoxicillin': {
      'dosing': '40 mg/kg/day divided 2-3 times',
      'duration': '10 days',
      'indications': 'Bacterial infections (strep, ear infections)',
      'prescription_required': true
    },
    'albuterol': {
      'dosing': '2-4 puffs every 4-6 hours',
      'indications': 'Asthma, croup',
      'age_restrictions': 'All ages',
      'prescription_required': true
    },
    'dextromethorphan': {
      'dosing': '1-2 mg/kg every 6-8 hours',
      'age_restrictions': '4 years and older',
      'indications': 'Dry cough',
      'brand_names': ['Robitussin DM']
    },
    'honey': {
      'dosing': '1/2 to 1 teaspoon as needed',
      'age_restrictions': '1 year and older',
      'precautions': 'Never give honey to infants <1 year (botulism risk)',
      'indications': 'Cough relief'
    }
  };

  // Home remedies database
  static const Map<String, List<String>> _homeRemedies = {
    'fever': [
      'Keep child hydrated (Pedialyte)',
      'Dress lightly, avoid bundling',
      'Lukewarm sponge baths (not cold)',
      'Rest in cool environment',
      'Monitor for dehydration signs'
    ],
    'cough': [
      'Humidified air (cool-mist humidifier)',
      'Honey (1 tsp for ages >1 year, at bedtime)',
      'Elevate head while sleeping',
      'Avoid smoke/secondhand exposure',
      'Warm fluids (tea with honey for older children)'
    ],
    'vomiting': [
      'Small sips of clear fluids (Pedialyte)',
      'Bland diet (BRAT: bananas, rice, applesauce, toast)',
      'Rest, avoid dairy/sugary foods',
      'Gradual return to normal diet'
    ],
    'diarrhea': [
      'Hydration (ORS solution)',
      'Probiotics (yogurt)',
      'Avoid dairy/caffeine',
      'BRAT diet',
      'Monitor for dehydration'
    ],
    'ear_pain': [
      'Warm compress on ear',
      'Elevate head while sleeping',
      'Avoid water in ear',
      'Pain relief with ibuprofen'
    ],
    'sore_throat': [
      'Saltwater gargle (1/4 tsp salt in water, ages >6)',
      'Honey-lemon tea',
      'Lozenges (ages >5)',
      'Warm fluids'
    ],
    'rash': [
      'Oatmeal baths',
      'Cool compresses',
      'Avoid scratching',
      'Identify and avoid triggers'
    ],
    'headache': [
      'Dark quiet room',
      'Cold compress',
      'Hydration',
      'Regular sleep',
      'Avoid screens/caffeine'
    ]
  };

  // Red flags database
  static const Map<String, List<String>> _redFlags = {
    'fever': [
      'Fever >3 days (or >24 hours in infants <3 months)',
      'Fever >104°F',
      'Fever with rash/stiff neck',
      'Fever with altered mental status',
      'Fever in immunocompromised child'
    ],
    'breathing_difficulty': [
      'Any breathing difficulty is urgent',
      'Blue lips or labored breathing (call 911)',
      'Using extra muscles to breathe',
      'Fast breathing with nostril flaring',
      'Audible wheezing or stridor'
    ],
    'vomiting': [
      '>6 episodes/day',
      'Blood or bile in vomit',
      'Signs of dehydration',
      'Projectile vomiting in infants 2-8 weeks',
      'Vomiting with severe headache'
    ],
    'diarrhea': [
      'Bloody stools',
      '>10 episodes/day',
      'Signs of dehydration',
      'Diarrhea lasting >2 weeks',
      'Recent antibiotic use'
    ],
    'rash': [
      'Spreading rapidly',
      'Fever with rash',
      'Blistering or petechiae',
      'Rash with difficulty breathing',
      'Rash covering large body areas'
    ],
    'headache': [
      'Sudden or severe headache',
      'Headache with vomiting',
      'Headache with neck stiffness',
      'Headache after head injury',
      'Worst headache of life'
    ]
  };

  // Generate treatment recommendation using AI
  Future<TreatmentRecommendation> generateTreatmentRecommendation(
    String symptom, 
    int age, 
    Map<String, dynamic> context
  ) async {
    try {
      final prompt = _buildTreatmentPrompt(symptom, age, context);
      final response = await _callOpenAI(prompt);
      
      return _parseTreatmentResponse(response, symptom, age);
    } catch (e) {
      // Fallback to rule-based recommendations
      return _generateRuleBasedTreatment(symptom, age, context);
    }
  }

  // Build AI prompt for treatment recommendation
  String _buildTreatmentPrompt(String symptom, int age, Map<String, dynamic> context) {
    return '''
    As a pediatrician, based on the following information, provide a comprehensive treatment recommendation:
    
    Symptom: $symptom
    Age: $age years
    Context: ${jsonEncode(context)}
    
    Please provide:
    1. **Diagnosis**: Most likely cause
    2. **Treatment Recommendations**:
       - OTC medications (with age-appropriate dosing)
       - Prescription medications (if needed)
       - Home remedies
       - Precautions
    3. **Red flags** to watch for
    4. **When to see doctor**
    
    **IMPORTANT**: Include this disclaimer:
    "Based on my knowledge as a simulated pediatrician, this is my suggested diagnosis and treatment. If you're not sure or symptoms persist, always reach out to your doctor or seek immediate medical care."
    
    Make response conversational, like a doctor talking to parent/patient.
    ''';
  }

  // Call OpenAI API for treatment recommendation
  Future<String> _callOpenAI(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config.openaiApiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a board-certified pediatrician with expertise in treating children of all ages. Provide evidence-based treatment recommendations with appropriate disclaimers.'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get treatment recommendation: ${response.statusCode}');
    }
  }

  // Parse AI response into structured treatment recommendation
  TreatmentRecommendation _parseTreatmentResponse(String response, String symptom, int age) {
    // Parse AI response and extract structured data
    // This is a simplified parser - in production, use more robust parsing
    return TreatmentRecommendation(
      diagnosis: _extractDiagnosis(response),
      otcMedications: _extractOTCMedications(response, age),
      prescriptionMedications: _extractPrescriptionMedications(response),
      homeRemedies: _getHomeRemedies(symptom),
      precautions: _extractPrecautions(response),
      redFlags: _getRedFlags(symptom),
      whenToSeeDoctor: _extractWhenToSeeDoctor(response),
      disclaimer: _getDisclaimer(),
      aiResponse: response,
    );
  }

  // Generate rule-based treatment as fallback
  TreatmentRecommendation _generateRuleBasedTreatment(String symptom, int age, Map<String, dynamic> context) {
    return TreatmentRecommendation(
      diagnosis: _getRuleBasedDiagnosis(symptom),
      otcMedications: _getRuleBasedOTCMedications(symptom, age),
      prescriptionMedications: _getRuleBasedPrescriptionMedications(symptom),
      homeRemedies: _getHomeRemedies(symptom),
      precautions: _getRuleBasedPrecautions(symptom),
      redFlags: _getRedFlags(symptom),
      whenToSeeDoctor: _getRuleBasedWhenToSeeDoctor(symptom),
      disclaimer: _getDisclaimer(),
      aiResponse: 'Rule-based recommendation (AI unavailable)',
    );
  }

  // Helper methods for parsing and rule-based recommendations
  String _extractDiagnosis(String response) {
    // Extract diagnosis from AI response
    // Simplified implementation
    if (response.toLowerCase().contains('viral')) return 'Viral infection';
    if (response.toLowerCase().contains('bacterial')) return 'Bacterial infection';
    return 'Symptom-based assessment';
  }

  List<Medication> _extractOTCMedications(String response, int age) {
    // Extract OTC medications from AI response
    final medications = <Medication>[];
    
    if (response.toLowerCase().contains('acetaminophen') || response.toLowerCase().contains('tylenol')) {
      medications.add(Medication(
        name: 'Acetaminophen',
        dosing: _medicationDatabase['acetaminophen']!['dosing'],
        ageRestrictions: _medicationDatabase['acetaminophen']!['age_restrictions'],
        precautions: _medicationDatabase['acetaminophen']!['precautions'],
        isOTC: true,
      ));
    }
    
    if (response.toLowerCase().contains('ibuprofen') || response.toLowerCase().contains('motrin')) {
      if (age >= 6) {
        medications.add(Medication(
          name: 'Ibuprofen',
          dosing: _medicationDatabase['ibuprofen']!['dosing'],
          ageRestrictions: _medicationDatabase['ibuprofen']!['age_restrictions'],
          precautions: _medicationDatabase['ibuprofen']!['precautions'],
          isOTC: true,
        ));
      }
    }
    
    return medications;
  }

  List<Medication> _extractPrescriptionMedications(String response) {
    // Extract prescription medications from AI response
    final medications = <Medication>[];
    
    if (response.toLowerCase().contains('amoxicillin')) {
      medications.add(Medication(
        name: 'Amoxicillin',
        dosing: _medicationDatabase['amoxicillin']!['dosing'],
        duration: _medicationDatabase['amoxicillin']!['duration'],
        indications: _medicationDatabase['amoxicillin']!['indications'],
        isOTC: false,
        prescriptionRequired: true,
      ));
    }
    
    return medications;
  }

  List<String> _getHomeRemedies(String symptom) {
    return _homeRemedies[symptom.toLowerCase()] ?? [
      'Rest and hydration',
      'Monitor symptoms',
      'Comfort measures'
    ];
  }

  List<String> _extractPrecautions(String response) {
    // Extract precautions from AI response
    final precautions = <String>[];
    
    if (response.toLowerCase().contains('aspirin')) {
      precautions.add('Never use aspirin in children (Reye syndrome risk)');
    }
    
    if (response.toLowerCase().contains('honey') && response.toLowerCase().contains('infant')) {
      precautions.add('Never give honey to infants <1 year (botulism risk)');
    }
    
    return precautions;
  }

  List<String> _getRedFlags(String symptom) {
    return _redFlags[symptom.toLowerCase()] ?? [
      'Severe symptoms',
      'Symptoms lasting >1 week',
      'Signs of dehydration',
      'High fever or difficulty breathing'
    ];
  }

  String _extractWhenToSeeDoctor(String response) {
    // Extract when to see doctor from AI response
    if (response.toLowerCase().contains('emergency') || response.toLowerCase().contains('911')) {
      return 'Seek immediate medical care';
    }
    if (response.toLowerCase().contains('doctor') || response.toLowerCase().contains('physician')) {
      return 'Consult your doctor within 24-48 hours';
    }
    return 'Monitor symptoms and consult doctor if they persist or worsen';
  }

  String _getDisclaimer() {
    return 'Based on my knowledge as a simulated pediatrician, this is my suggested diagnosis and treatment. If you\'re not sure or symptoms persist, always reach out to your doctor or seek immediate medical care.';
  }

  // Rule-based fallback methods
  String _getRuleBasedDiagnosis(String symptom) {
    switch (symptom.toLowerCase()) {
      case 'fever':
        return 'Viral infection (most common)';
      case 'cough':
        return 'Upper respiratory infection';
      case 'vomiting':
        return 'Viral gastroenteritis';
      case 'diarrhea':
        return 'Viral gastroenteritis';
      default:
        return 'Symptom-based assessment';
    }
  }

  List<Medication> _getRuleBasedOTCMedications(String symptom, int age) {
    final medications = <Medication>[];
    
    switch (symptom.toLowerCase()) {
      case 'fever':
        medications.add(Medication(
          name: 'Acetaminophen',
          dosing: _medicationDatabase['acetaminophen']!['dosing'],
          ageRestrictions: _medicationDatabase['acetaminophen']!['age_restrictions'],
          precautions: _medicationDatabase['acetaminophen']!['precautions'],
          isOTC: true,
        ));
        if (age >= 6) {
          medications.add(Medication(
            name: 'Ibuprofen',
            dosing: _medicationDatabase['ibuprofen']!['dosing'],
            ageRestrictions: _medicationDatabase['ibuprofen']!['age_restrictions'],
            precautions: _medicationDatabase['ibuprofen']!['precautions'],
            isOTC: true,
          ));
        }
        break;
      case 'cough':
        if (age >= 4) {
          medications.add(Medication(
            name: 'Dextromethorphan',
            dosing: _medicationDatabase['dextromethorphan']!['dosing'],
            ageRestrictions: _medicationDatabase['dextromethorphan']!['age_restrictions'],
            indications: _medicationDatabase['dextromethorphan']!['indications'],
            isOTC: true,
          ));
        }
        if (age >= 1) {
          medications.add(Medication(
            name: 'Honey',
            dosing: _medicationDatabase['honey']!['dosing'],
            ageRestrictions: _medicationDatabase['honey']!['age_restrictions'],
            precautions: _medicationDatabase['honey']!['precautions'],
            indications: _medicationDatabase['honey']!['indications'],
            isOTC: true,
          ));
        }
        break;
    }
    
    return medications;
  }

  List<Medication> _getRuleBasedPrescriptionMedications(String symptom) {
    final medications = <Medication>[];
    
    switch (symptom.toLowerCase()) {
      case 'ear_pain':
      case 'sore_throat':
        medications.add(Medication(
          name: 'Amoxicillin',
          dosing: _medicationDatabase['amoxicillin']!['dosing'],
          duration: _medicationDatabase['amoxicillin']!['duration'],
          indications: _medicationDatabase['amoxicillin']!['indications'],
          isOTC: false,
          prescriptionRequired: true,
        ));
        break;
    }
    
    return medications;
  }

  List<String> _getRuleBasedPrecautions(String symptom) {
    switch (symptom.toLowerCase()) {
      case 'fever':
        return [
          'Never use aspirin in children (Reye syndrome risk)',
          'Alternate acetaminophen and ibuprofen if needed',
          'Monitor for dehydration signs'
        ];
      case 'cough':
        return [
          'Avoid over-the-counter cough medicines in children <4 years',
          'Never give honey to infants <1 year (botulism risk)',
          'Monitor for breathing difficulty'
        ];
      default:
        return [
          'Monitor symptoms closely',
          'Seek medical care if symptoms worsen'
        ];
    }
  }

  String _getRuleBasedWhenToSeeDoctor(String symptom) {
    switch (symptom.toLowerCase()) {
      case 'fever':
        return 'Seek care if fever >3 days, >104°F, or with rash/stiff neck';
      case 'breathing_difficulty':
        return 'Seek immediate medical care for any breathing difficulty';
      case 'vomiting':
        return 'Seek care if >6 episodes/day, blood/bile in vomit, or dehydration';
      case 'diarrhea':
        return 'Seek care if bloody, >10 episodes/day, or dehydration';
      default:
        return 'Consult doctor if symptoms persist or worsen';
    }
  }
}

// Data classes for treatment recommendations
class TreatmentRecommendation {
  final String diagnosis;
  final List<Medication> otcMedications;
  final List<Medication> prescriptionMedications;
  final List<String> homeRemedies;
  final List<String> precautions;
  final List<String> redFlags;
  final String whenToSeeDoctor;
  final String disclaimer;
  final String aiResponse;

  TreatmentRecommendation({
    required this.diagnosis,
    required this.otcMedications,
    required this.prescriptionMedications,
    required this.homeRemedies,
    required this.precautions,
    required this.redFlags,
    required this.whenToSeeDoctor,
    required this.disclaimer,
    required this.aiResponse,
  });

  Map<String, dynamic> toJson() {
    return {
      'diagnosis': diagnosis,
      'otcMedications': otcMedications.map((m) => m.toJson()).toList(),
      'prescriptionMedications': prescriptionMedications.map((m) => m.toJson()).toList(),
      'homeRemedies': homeRemedies,
      'precautions': precautions,
      'redFlags': redFlags,
      'whenToSeeDoctor': whenToSeeDoctor,
      'disclaimer': disclaimer,
      'aiResponse': aiResponse,
    };
  }
}

class Medication {
  final String name;
  final String dosing;
  final String? duration;
  final String? indications;
  final String? ageRestrictions;
  final String? precautions;
  final bool isOTC;
  final bool prescriptionRequired;

  Medication({
    required this.name,
    required this.dosing,
    this.duration,
    this.indications,
    this.ageRestrictions,
    this.precautions,
    required this.isOTC,
    this.prescriptionRequired = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosing': dosing,
      'duration': duration,
      'indications': indications,
      'ageRestrictions': ageRestrictions,
      'precautions': precautions,
      'isOTC': isOTC,
      'prescriptionRequired': prescriptionRequired,
    };
  }
} 