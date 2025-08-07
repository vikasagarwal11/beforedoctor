import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// Service for fetching and processing PubMed pediatric symptom treatment datasets
class PubMedDatasetService {
  static final PubMedDatasetService _instance = PubMedDatasetService._internal();
  factory PubMedDatasetService() => _instance;
  PubMedDatasetService._internal();

  final Logger _logger = Logger();
  
  // PubMed API configuration
  static const String _baseUrl = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils';
  static const String _searchUrl = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi';
  static const String _fetchUrl = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi';
  static const String _summaryUrl = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi';
  
  // Dataset cache
  final Map<String, dynamic> _datasetCache = {};
  final List<Map<String, dynamic>> _pediatricStudies = [];
  
  // Search queries for pediatric symptom treatment datasets
  static const List<String> _searchQueries = [
    'pediatric symptom treatment dataset',
    'child symptom management clinical trial',
    'pediatric fever treatment study',
    'child cough treatment dataset',
    'pediatric pain management clinical',
    'child vomiting treatment study',
    'pediatric rash treatment dataset',
    'child diarrhea treatment clinical',
    'pediatric respiratory symptoms study',
    'child allergy treatment dataset',
    'pediatric medication safety study',
    'child immunization reaction dataset',
    'pediatric emergency symptoms study',
    'child growth monitoring dataset',
    'pediatric developmental screening'
  ];

  /// Initialize the PubMed dataset service
  Future<void> initialize() async {
    try {
      _logger.i('🔬 Initializing PubMed Dataset Service');
      await _loadCachedDatasets();
      await _fetchPediatricStudies();
      _logger.i('✅ PubMed Dataset Service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize PubMed Dataset Service: $e');
      rethrow;
    }
  }

  /// Load cached datasets from local storage
  Future<void> _loadCachedDatasets() async {
    try {
      // TODO: Implement local storage for cached datasets
      _logger.i('📦 Loading cached PubMed datasets');
    } catch (e) {
      _logger.w('⚠️ No cached datasets found: $e');
    }
  }

  /// Fetch pediatric studies from PubMed
  Future<void> _fetchPediatricStudies() async {
    try {
      _logger.i('🔍 Fetching pediatric studies from PubMed');
      
      for (String query in _searchQueries) {
        final studies = await _searchPubMed(query);
        _pediatricStudies.addAll(studies);
        
        // Rate limiting to respect PubMed API guidelines
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _logger.i('✅ Fetched ${_pediatricStudies.length} pediatric studies');
    } catch (e) {
      _logger.e('❌ Failed to fetch pediatric studies: $e');
    }
  }

  /// Search PubMed for specific query
  Future<List<Map<String, dynamic>>> _searchPubMed(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_searchUrl?db=pubmed&term=$query&retmax=50&retmode=json'),
        headers: {'User-Agent': 'BeforeDoctor/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final idList = data['esearchresult']['idlist'] as List;
        
        List<Map<String, dynamic>> studies = [];
        for (String id in idList) {
          final study = await _fetchStudyDetails(id);
          if (study.isNotEmpty) {
            studies.add(study);
          }
        }
        
        return studies;
      } else {
        _logger.w('⚠️ PubMed search failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('❌ PubMed search error: $e');
      return [];
    }
  }

  /// Fetch detailed study information
  Future<Map<String, dynamic>> _fetchStudyDetails(String pmid) async {
    try {
      final response = await http.get(
        Uri.parse('$_summaryUrl?db=pubmed&id=$pmid&retmode=json'),
        headers: {'User-Agent': 'BeforeDoctor/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'][pmid];
        
        return {
          'pmid': pmid,
          'title': result['title'] ?? '',
          'abstract': result['abstract'] ?? '',
          'authors': result['authors']?.map((a) => a['name']).toList() ?? [],
          'journal': result['fulljournalname'] ?? '',
          'pubdate': result['pubdate'] ?? '',
          'keywords': result['keywords'] ?? [],
          'mesh_terms': result['meshterms'] ?? [],
          'study_type': _extractStudyType(result['title'] ?? '', result['abstract'] ?? ''),
          'symptom_focus': _extractSymptomFocus(result['title'] ?? '', result['abstract'] ?? ''),
          'treatment_mentioned': _extractTreatmentMention(result['title'] ?? '', result['abstract'] ?? ''),
          'age_group': _extractAgeGroup(result['title'] ?? '', result['abstract'] ?? ''),
          'sample_size': _extractSampleSize(result['abstract'] ?? ''),
          'relevance_score': _calculateRelevanceScore(result['title'] ?? '', result['abstract'] ?? ''),
        };
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch study details for PMID $pmid: $e');
    }
    
    return {};
  }

  /// Extract study type from title and abstract
  String _extractStudyType(String title, String abstract) {
    final text = '${title.toLowerCase()} ${abstract.toLowerCase()}';
    
    if (text.contains('randomized') || text.contains('rct')) return 'RCT';
    if (text.contains('systematic review') || text.contains('meta-analysis')) return 'Review';
    if (text.contains('case study') || text.contains('case report')) return 'Case Study';
    if (text.contains('cohort study')) return 'Cohort';
    if (text.contains('cross-sectional')) return 'Cross-sectional';
    if (text.contains('observational')) return 'Observational';
    
    return 'Other';
  }

  /// Extract symptom focus from title and abstract
  List<String> _extractSymptomFocus(String title, String abstract) {
    final text = '${title.toLowerCase()} ${abstract.toLowerCase()}';
    final symptoms = <String>[];
    
    final symptomKeywords = {
      'fever': ['fever', 'pyrexia', 'temperature'],
      'cough': ['cough', 'coughing', 'respiratory'],
      'vomiting': ['vomit', 'vomiting', 'emesis'],
      'diarrhea': ['diarrhea', 'diarrhoea', 'loose stools'],
      'pain': ['pain', 'ache', 'discomfort'],
      'rash': ['rash', 'eruption', 'dermatitis'],
      'fatigue': ['fatigue', 'tiredness', 'lethargy'],
      'headache': ['headache', 'head pain'],
      'nausea': ['nausea', 'queasy'],
      'wheezing': ['wheezing', 'wheeze'],
      'sore throat': ['sore throat', 'pharyngitis'],
      'runny nose': ['runny nose', 'rhinorrhea'],
      'ear pain': ['ear pain', 'otalgia'],
      'abdominal pain': ['abdominal pain', 'stomach ache'],
      'dehydration': ['dehydration', 'fluid loss'],
    };
    
    for (final entry in symptomKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          symptoms.add(entry.key);
          break;
        }
      }
    }
    
    return symptoms.toSet().toList();
  }

  /// Extract treatment mentions from title and abstract
  List<String> _extractTreatmentMention(String title, String abstract) {
    final text = '${title.toLowerCase()} ${abstract.toLowerCase()}';
    final treatments = <String>[];
    
    final treatmentKeywords = {
      'antibiotics': ['antibiotic', 'antibiotics', 'penicillin', 'amoxicillin'],
      'antipyretics': ['antipyretic', 'acetaminophen', 'paracetamol', 'ibuprofen'],
      'antihistamines': ['antihistamine', 'benadryl', 'diphenhydramine'],
      'bronchodilators': ['bronchodilator', 'albuterol', 'salbutamol'],
      'corticosteroids': ['corticosteroid', 'prednisone', 'dexamethasone'],
      'oral rehydration': ['oral rehydration', 'ors', 'electrolyte'],
      'vaccination': ['vaccine', 'vaccination', 'immunization'],
      'surgery': ['surgery', 'surgical', 'operation'],
      'physical therapy': ['physical therapy', 'physiotherapy'],
      'dietary changes': ['diet', 'nutrition', 'feeding'],
    };
    
    for (final entry in treatmentKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          treatments.add(entry.key);
          break;
        }
      }
    }
    
    return treatments.toSet().toList();
  }

  /// Extract age group from title and abstract
  String _extractAgeGroup(String title, String abstract) {
    final text = '${title.toLowerCase()} ${abstract.toLowerCase()}';
    
    if (text.contains('neonatal') || text.contains('newborn')) return 'Neonatal (0-28 days)';
    if (text.contains('infant') || text.contains('baby')) return 'Infant (1-12 months)';
    if (text.contains('toddler')) return 'Toddler (1-3 years)';
    if (text.contains('preschool')) return 'Preschool (3-5 years)';
    if (text.contains('school age') || text.contains('school-age')) return 'School age (6-12 years)';
    if (text.contains('adolescent') || text.contains('teen')) return 'Adolescent (13-18 years)';
    if (text.contains('pediatric') || text.contains('children')) return 'Pediatric (0-18 years)';
    
    return 'Not specified';
  }

  /// Extract sample size from abstract
  int _extractSampleSize(String abstract) {
    try {
      final regex = RegExp(r'(\d+)\s*(?:patients?|children|subjects?|participants?)', caseSensitive: false);
      final match = regex.firstMatch(abstract);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      _logger.w('⚠️ Failed to extract sample size: $e');
    }
    return 0;
  }

  /// Calculate relevance score for pediatric symptom treatment
  double _calculateRelevanceScore(String title, String abstract) {
    double score = 0.0;
    final text = '${title.toLowerCase()} ${abstract.toLowerCase()}';
    
    // Pediatric focus
    if (text.contains('pediatric') || text.contains('child') || text.contains('infant')) score += 0.3;
    
    // Symptom focus
    if (_extractSymptomFocus(title, abstract).isNotEmpty) score += 0.2;
    
    // Treatment focus
    if (_extractTreatmentMention(title, abstract).isNotEmpty) score += 0.2;
    
    // Recent publication (last 10 years)
    final currentYear = DateTime.now().year;
    final yearMatch = RegExp(r'(\d{4})').firstMatch(text);
    if (yearMatch != null) {
      final year = int.tryParse(yearMatch.group(1)!);
      if (year != null && currentYear - year <= 10) score += 0.1;
    }
    
    // Study quality indicators
    if (text.contains('randomized') || text.contains('systematic review')) score += 0.1;
    if (text.contains('clinical trial')) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  /// Get relevant studies for a specific symptom
  List<Map<String, dynamic>> getRelevantStudies(String symptom) {
    final relevantStudies = <Map<String, dynamic>>[];
    
    for (final study in _pediatricStudies) {
      final symptoms = study['symptom_focus'] as List<String>;
      if (symptoms.any((s) => s.toLowerCase().contains(symptom.toLowerCase()))) {
        relevantStudies.add(study);
      }
    }
    
    // Sort by relevance score
    relevantStudies.sort((a, b) => (b['relevance_score'] as double).compareTo(a['relevance_score'] as double));
    
    return relevantStudies.take(10).toList();
  }

  /// Get treatment recommendations based on symptoms
  Map<String, dynamic> getTreatmentRecommendations(String symptom, Map<String, String> childMetadata) {
    final relevantStudies = getRelevantStudies(symptom);
    final recommendations = <String, dynamic>{
      'symptom': symptom,
      'studies_found': relevantStudies.length,
      'treatments': <String>[],
      'evidence_level': 'Limited',
      'recommendations': <String>[],
      'cautions': <String>[],
      'age_considerations': <String>[],
    };
    
    if (relevantStudies.isEmpty) {
      recommendations['recommendations'].add('No specific treatment studies found for this symptom.');
      return recommendations;
    }
    
    // Extract treatments from studies
    final allTreatments = <String, int>{};
    for (final study in relevantStudies) {
      final treatments = study['treatment_mentioned'] as List<String>;
      for (final treatment in treatments) {
        allTreatments[treatment] = (allTreatments[treatment] ?? 0) + 1;
      }
    }
    
    // Get most common treatments
    final sortedTreatments = allTreatments.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    recommendations['treatments'] = sortedTreatments.take(5).map((e) => e.key).toList();
    
    // Generate age-specific recommendations
    final childAge = int.tryParse(childMetadata['child_age'] ?? '0') ?? 0;
    if (childAge < 2) {
      recommendations['age_considerations'].add('Consult pediatrician before any medication');
      recommendations['age_considerations'].add('Monitor for signs of dehydration');
    } else if (childAge < 6) {
      recommendations['age_considerations'].add('Use age-appropriate dosing');
      recommendations['age_considerations'].add('Avoid aspirin in children');
    }
    
    // Evidence level based on study types
    final rctCount = relevantStudies.where((s) => s['study_type'] == 'RCT').length;
    final reviewCount = relevantStudies.where((s) => s['study_type'] == 'Review').length;
    
    if (rctCount > 2) {
      recommendations['evidence_level'] = 'Strong';
    } else if (reviewCount > 1 || rctCount > 0) {
      recommendations['evidence_level'] = 'Moderate';
    }
    
    // Generate specific recommendations
    if (symptom.toLowerCase().contains('fever')) {
      recommendations['recommendations'].add('Monitor temperature regularly');
      recommendations['recommendations'].add('Ensure adequate hydration');
      recommendations['cautions'].add('Seek medical attention if fever >104°F (40°C)');
    } else if (symptom.toLowerCase().contains('cough')) {
      recommendations['recommendations'].add('Use honey for children over 1 year');
      recommendations['recommendations'].add('Maintain humid environment');
      recommendations['cautions'].add('Avoid cough suppressants in young children');
    }
    
    return recommendations;
  }

  /// Get dataset statistics
  Map<String, dynamic> getDatasetStatistics() {
    final totalStudies = _pediatricStudies.length;
    final studyTypes = <String, int>{};
    final ageGroups = <String, int>{};
    final symptoms = <String, int>{};
    
    for (final study in _pediatricStudies) {
      // Study types
      final studyType = study['study_type'] as String;
      studyTypes[studyType] = (studyTypes[studyType] ?? 0) + 1;
      
      // Age groups
      final ageGroup = study['age_group'] as String;
      ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + 1;
      
      // Symptoms
      final studySymptoms = study['symptom_focus'] as List<String>;
      for (final symptom in studySymptoms) {
        symptoms[symptom] = (symptoms[symptom] ?? 0) + 1;
      }
    }
    
    return {
      'total_studies': totalStudies,
      'study_types': studyTypes,
      'age_groups': ageGroups,
      'symptoms_covered': symptoms,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Export dataset for backup
  Future<void> exportDataset(String filePath) async {
    try {
      final data = {
        'studies': _pediatricStudies,
        'statistics': getDatasetStatistics(),
        'export_date': DateTime.now().toIso8601String(),
      };
      
      final file = File(filePath);
      await file.writeAsString(json.encode(data));
      _logger.i('📤 Dataset exported to: $filePath');
    } catch (e) {
      _logger.e('❌ Failed to export dataset: $e');
      rethrow;
    }
  }

  /// Import dataset from backup
  Future<void> importDataset(String filePath) async {
    try {
      final file = File(filePath);
      final data = json.decode(await file.readAsString());
      
      _pediatricStudies.clear();
      _pediatricStudies.addAll((data['studies'] as List).cast<Map<String, dynamic>>());
      
      _logger.i('📥 Dataset imported from: $filePath');
    } catch (e) {
      _logger.e('❌ Failed to import dataset: $e');
      rethrow;
    }
  }

  /// Clear all cached data
  void clearCache() {
    _datasetCache.clear();
    _pediatricStudies.clear();
    _logger.i('🗑️ PubMed dataset cache cleared');
  }

  /// Dispose of the service
  void dispose() {
    clearCache();
    _logger.i('🔬 PubMed Dataset Service disposed');
  }
} 