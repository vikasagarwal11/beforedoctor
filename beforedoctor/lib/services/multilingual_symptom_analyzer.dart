import 'package:logger/logger.dart';

class MultilingualSymptomAnalyzer {
  static final MultilingualSymptomAnalyzer _instance = MultilingualSymptomAnalyzer._internal();
  factory MultilingualSymptomAnalyzer() => _instance;
  MultilingualSymptomAnalyzer._internal();

  final Logger _logger = Logger();

  // Multi-language symptom mappings
  final Map<String, Map<String, List<String>>> _multilingualSymptoms = {
    'en': {
      'fever': ['fever', 'temperature', 'hot', 'burning up'],
      'cough': ['cough', 'coughing', 'dry cough', 'productive cough'],
      'headache': ['headache', 'head pain', 'migraine'],
      'fatigue': ['fatigue', 'tired', 'exhausted', 'weak'],
      'nausea': ['nausea', 'sick to stomach', 'queasy'],
      'vomiting': ['vomiting', 'throwing up', 'puking'],
      'diarrhea': ['diarrhea', 'loose stools', 'runny poop'],
      'abdominal pain': ['stomach pain', 'belly pain', 'abdominal pain'],
      'sore throat': ['sore throat', 'throat pain', 'swallowing pain'],
      'runny nose': ['runny nose', 'nasal discharge', 'stuffy nose'],
      'difficulty breathing': ['difficulty breathing', 'shortness of breath', 'wheezing'],
      'blue lips': ['blue lips', 'cyanosis', 'bluish lips'],
      'seizures': ['seizures', 'convulsions', 'fits'],
      'stiff neck': ['stiff neck', 'neck pain', 'meningitis'],
    },
    'es': {
      'fever': ['fiebre', 'temperatura', 'caliente'],
      'cough': ['tos', 'tosiendo', 'tos seca'],
      'headache': ['dolor de cabeza', 'migraña'],
      'fatigue': ['fatiga', 'cansado', 'agotado'],
      'nausea': ['náusea', 'malestar estomacal'],
      'vomiting': ['vómito', 'vomitar'],
      'diarrhea': ['diarrea', 'heces sueltas'],
      'abdominal pain': ['dolor de estómago', 'dolor abdominal'],
      'sore throat': ['dolor de garganta', 'garganta irritada'],
      'runny nose': ['nariz que moquea', 'secreción nasal'],
      'difficulty breathing': ['dificultad para respirar', 'falta de aire'],
      'blue lips': ['labios azules', 'cianosis'],
      'seizures': ['convulsiones', 'ataques'],
      'stiff neck': ['rigidez del cuello', 'dolor de cuello'],
    },
    'zh': {
      'fever': ['发烧', '发热', '体温高'],
      'cough': ['咳嗽', '干咳', '咳痰'],
      'headache': ['头痛', '偏头痛'],
      'fatigue': ['疲劳', '疲倦', '虚弱'],
      'nausea': ['恶心', '反胃'],
      'vomiting': ['呕吐', '吐'],
      'diarrhea': ['腹泻', '拉肚子'],
      'abdominal pain': ['腹痛', '肚子疼'],
      'sore throat': ['喉咙痛', '咽痛'],
      'runny nose': ['流鼻涕', '鼻塞'],
      'difficulty breathing': ['呼吸困难', '气短'],
      'blue lips': ['嘴唇发紫', '发绀'],
      'seizures': ['抽搐', '癫痫'],
      'stiff neck': ['脖子僵硬', '颈部疼痛'],
    },
    'fr': {
      'fever': ['fièvre', 'température', 'chaud'],
      'cough': ['toux', 'tousser', 'toux sèche'],
      'headache': ['mal de tête', 'migraine'],
      'fatigue': ['fatigue', 'fatigué', 'épuisé'],
      'nausea': ['nausée', 'mal au cœur'],
      'vomiting': ['vomissements', 'vomir'],
      'diarrhea': ['diarrhée', 'selles molles'],
      'abdominal pain': ['douleur abdominale', 'mal au ventre'],
      'sore throat': ['mal de gorge', 'gorge irritée'],
      'runny nose': ['nez qui coule', 'écoulement nasal'],
      'difficulty breathing': ['difficulté à respirer', 'essoufflement'],
      'blue lips': ['lèvres bleues', 'cyanose'],
      'seizures': ['convulsions', 'crises'],
      'stiff neck': ['raideur du cou', 'douleur au cou'],
    }
  };

  /// Detect language from text
  String detectLanguage(String text) {
    final lowerText = text.toLowerCase();
    
    // Simple language detection based on common words
    if (_containsAny(lowerText, ['fiebre', 'tos', 'dolor', 'mal'])) {
      return 'es'; // Spanish
    } else if (_containsAny(lowerText, ['发烧', '咳嗽', '头痛', '发烧'])) {
      return 'zh'; // Chinese
    } else if (_containsAny(lowerText, ['fièvre', 'toux', 'mal', 'douleur'])) {
      return 'fr'; // French
    } else {
      return 'en'; // Default to English
    }
  }

  /// Extract symptoms from multilingual text
  List<String> extractSymptoms(String text) {
    try {
      final language = detectLanguage(text);
      final lowerText = text.toLowerCase();
      final foundSymptoms = <String>[];
      
      // Get symptom mappings for detected language
      final symptomMappings = _multilingualSymptoms[language] ?? _multilingualSymptoms['en']!;
      
      // Check each symptom category
      for (final entry in symptomMappings.entries) {
        final englishSymptom = entry.key;
        final multilingualTerms = entry.value;
        
        // Check if any term in this category is present
        for (final term in multilingualTerms) {
          if (lowerText.contains(term.toLowerCase())) {
            foundSymptoms.add(englishSymptom);
            break; // Found one term in this category, move to next
          }
        }
      }
      
      _logger.i('Extracted symptoms: $foundSymptoms from language: $language');
      return foundSymptoms;
      
    } catch (e) {
      _logger.e('Error extracting symptoms: $e');
      return [];
    }
  }

  /// Get symptom terms in specific language
  List<String> getSymptomTerms(String symptom, String language) {
    return _multilingualSymptoms[language]?[symptom] ?? _multilingualSymptoms['en']![symptom] ?? [];
  }

  /// Get all available languages
  List<String> getAvailableLanguages() {
    return _multilingualSymptoms.keys.toList();
  }

  /// Get emergency phrases in multiple languages
  Map<String, List<String>> getEmergencyPhrases() {
    return {
      'en': [
        'emergency',
        'immediate attention',
        'call 911',
        'urgent care',
        'emergency room'
      ],
      'es': [
        'emergencia',
        'atención inmediata',
        'llamar 911',
        'urgencias',
        'sala de emergencia'
      ],
      'zh': [
        '紧急',
        '立即就医',
        '拨打911',
        '急诊',
        '急诊室'
      ],
      'fr': [
        'urgence',
        'attention immédiate',
        'appeler 911',
        'soins urgents',
        'salle d\'urgence'
      ]
    };
  }

  /// Check if text contains emergency indicators
  bool hasEmergencyIndicators(String text) {
    final language = detectLanguage(text);
    final emergencyPhrases = getEmergencyPhrases()[language] ?? getEmergencyPhrases()['en']!;
    final lowerText = text.toLowerCase();
    
    return emergencyPhrases.any((phrase) => lowerText.contains(phrase.toLowerCase()));
  }

  /// Get severity indicators in multiple languages
  Map<String, Map<String, List<String>>> getSeverityIndicators() {
    return {
      'en': {
        'severe': ['severe', 'serious', 'critical', 'bad', 'terrible'],
        'moderate': ['moderate', 'medium', 'some', 'a bit'],
        'mild': ['mild', 'slight', 'little', 'minor']
      },
      'es': {
        'severe': ['severo', 'grave', 'crítico', 'malo', 'terrible'],
        'moderate': ['moderado', 'medio', 'algo', 'un poco'],
        'mild': ['leve', 'ligero', 'poco', 'menor']
      },
      'zh': {
        'severe': ['严重', '重症', '危急', '糟糕', '可怕'],
        'moderate': ['中等', '一般', '一些', '有点'],
        'mild': ['轻微', '轻微', '一点', '次要']
      },
      'fr': {
        'severe': ['sévère', 'grave', 'critique', 'mauvais', 'terrible'],
        'moderate': ['modéré', 'moyen', 'quelque', 'un peu'],
        'mild': ['léger', 'légère', 'peu', 'mineur']
      }
    };
  }

  /// Assess severity level from multilingual text
  String assessSeverityLevel(String text) {
    final language = detectLanguage(text);
    final severityIndicators = getSeverityIndicators()[language] ?? getSeverityIndicators()['en']!;
    final lowerText = text.toLowerCase();
    
    // Check for severe indicators first
    if (severityIndicators['severe']!.any((indicator) => lowerText.contains(indicator))) {
      return 'severe';
    }
    
    // Check for moderate indicators
    if (severityIndicators['moderate']!.any((indicator) => lowerText.contains(indicator))) {
      return 'moderate';
    }
    
    // Check for mild indicators
    if (severityIndicators['mild']!.any((indicator) => lowerText.contains(indicator))) {
      return 'mild';
    }
    
    return 'unknown';
  }

  /// Get temperature indicators in multiple languages
  Map<String, List<String>> getTemperatureIndicators() {
    return {
      'en': ['temperature', 'temp', 'fever', 'degrees', '°F', '°C'],
      'es': ['temperatura', 'temp', 'fiebre', 'grados', '°F', '°C'],
      'zh': ['体温', '温度', '发烧', '度', '°F', '°C'],
      'fr': ['température', 'temp', 'fièvre', 'degrés', '°F', '°C']
    };
  }

  /// Extract temperature from multilingual text
  double? extractTemperature(String text) {
    try {
      final language = detectLanguage(text);
      final temperatureIndicators = getTemperatureIndicators()[language] ?? getTemperatureIndicators()['en']!;
      final lowerText = text.toLowerCase();
      
      // Look for temperature patterns
      final regex = RegExp(r'(\d{2,3})[°\s]*(?:F|C|f|c)?');
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final tempValue = double.tryParse(match.group(1) ?? '');
        if (tempValue != null && tempValue >= 90 && tempValue <= 110) {
          return tempValue;
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('Error extracting temperature: $e');
      return null;
    }
  }

  /// Get multilingual recommendations
  Map<String, Map<String, String>> getMultilingualRecommendations() {
    return {
      'en': {
        'emergency': 'Seek immediate medical attention',
        'monitor': 'Monitor symptoms closely',
        'rest': 'Ensure adequate rest and hydration',
        'consult': 'Consult healthcare provider'
      },
      'es': {
        'emergency': 'Busque atención médica inmediata',
        'monitor': 'Monitoree los síntomas de cerca',
        'rest': 'Asegure descanso e hidratación adecuados',
        'consult': 'Consulte con un proveedor de salud'
      },
      'zh': {
        'emergency': '立即就医',
        'monitor': '密切监测症状',
        'rest': '确保充分休息和补水',
        'consult': '咨询医疗保健提供者'
      },
      'fr': {
        'emergency': 'Consultez immédiatement un médecin',
        'monitor': 'Surveillez les symptômes de près',
        'rest': 'Assurez un repos et une hydratation adéquats',
        'consult': 'Consultez un professionnel de la santé'
      }
    };
  }

  /// Helper method to check if text contains any of the given terms
  bool _containsAny(String text, List<String> terms) {
    return terms.any((term) => text.contains(term.toLowerCase()));
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing MultilingualSymptomAnalyzer...');
      // Add any initialization logic here
      _logger.i('MultilingualSymptomAnalyzer initialized successfully');
    } catch (e) {
      _logger.e('Error initializing MultilingualSymptomAnalyzer: $e');
      throw Exception('Error initializing MultilingualSymptomAnalyzer: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _logger.i('Disposing MultilingualSymptomAnalyzer...');
    // Add any cleanup logic here
  }
} 