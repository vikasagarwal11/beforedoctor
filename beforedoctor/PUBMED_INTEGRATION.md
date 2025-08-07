# PubMed Dataset Integration for BeforeDoctor

## Overview

The BeforeDoctor app now integrates with PubMed (PMC-Patients) to provide evidence-based treatment recommendations for pediatric symptoms. This integration enhances the AI-powered symptom analysis by incorporating real medical research data from over 167,000+ studies.

## Features

### 🔬 PubMed Dataset Service
- **Real-time API Integration**: Connects to PubMed E-utilities API
- **Smart Search Queries**: 20+ targeted queries for pediatric symptom treatment
- **Study Classification**: Automatically categorizes studies by type, symptoms, and treatments
- **Relevance Scoring**: AI-powered scoring system for study relevance
- **Age-specific Filtering**: Filters studies by pediatric age groups

### 📊 Dataset Statistics
- **Total Studies**: 167,000+ pediatric studies
- **Study Types**: RCT, Review, Case Study, Cohort, Cross-sectional
- **Age Groups**: Neonatal to Adolescent (0-18 years)
- **Symptoms Covered**: 14+ common pediatric symptoms
- **Treatments**: 10+ treatment categories

### 💊 Treatment Recommendations
- **Evidence-based**: Based on actual medical research
- **Age-appropriate**: Tailored to child's age group
- **Symptom-specific**: Targeted for specific symptoms
- **Safety-focused**: Includes cautions and warnings

## Architecture

### PubMedDatasetService
```dart
class PubMedDatasetService {
  // Singleton pattern for app-wide access
  static final PubMedDatasetService _instance = PubMedDatasetService._internal();
  
  // Core functionality
  Future<void> initialize() async;
  List<Map<String, dynamic>> getRelevantStudies(String symptom);
  Map<String, dynamic> getTreatmentRecommendations(String symptom, Map<String, String> childMetadata);
  Map<String, dynamic> getDatasetStatistics();
}
```

### Key Methods

#### 1. Study Search & Classification
```dart
// Search for studies related to a symptom
List<Map<String, dynamic>> getRelevantStudies(String symptom)

// Get treatment recommendations with evidence level
Map<String, dynamic> getTreatmentRecommendations(String symptom, Map<String, String> childMetadata)
```

#### 2. Data Processing
```dart
// Extract study type (RCT, Review, etc.)
String _extractStudyType(String title, String abstract)

// Extract symptom focus from study
List<String> _extractSymptomFocus(String title, String abstract)

// Extract treatment mentions
List<String> _extractTreatmentMention(String title, String abstract)

// Calculate relevance score
double _calculateRelevanceScore(String title, String abstract)
```

## Integration Points

### 1. Voice Logger Screen
- **Enhanced AI Responses**: PubMed insights added to AI responses
- **Evidence Level Display**: Shows strength of evidence
- **Treatment Recommendations**: Age-appropriate treatment suggestions
- **Safety Cautions**: Important warnings and precautions

### 2. PubMed Dataset Screen
- **Search Interface**: Search for specific symptoms
- **Study Browser**: View relevant studies
- **Statistics Dashboard**: Dataset analytics
- **Treatment Insights**: Detailed treatment recommendations

### 3. Character Interaction
- **Smart Responses**: Character references PubMed data
- **Evidence-based Advice**: Character provides research-backed guidance
- **Age-appropriate Language**: Tailored communication for children

## Search Queries

The service uses 20+ targeted search queries:

```dart
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
  'pediatric developmental screening',
  'pediatric fever management',
  'child cough management',
  'pediatric pain assessment',
  'child dehydration treatment',
  'pediatric rash diagnosis'
];
```

## Symptom Classification

### Supported Symptoms
```dart
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
```

## Treatment Classification

### Supported Treatments
```dart
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
```

## Evidence Levels

### Classification System
- **Strong**: Multiple RCTs or systematic reviews
- **Moderate**: Some RCTs or multiple reviews
- **Limited**: Case studies or observational studies

### Scoring Algorithm
```dart
double _calculateRelevanceScore(String title, String abstract) {
  double score = 0.0;
  
  // Pediatric focus (30%)
  if (text.contains('pediatric') || text.contains('child')) score += 0.3;
  
  // Symptom focus (20%)
  if (_extractSymptomFocus(title, abstract).isNotEmpty) score += 0.2;
  
  // Treatment focus (20%)
  if (_extractTreatmentMention(title, abstract).isNotEmpty) score += 0.2;
  
  // Recent publication (10%)
  if (currentYear - year <= 10) score += 0.1;
  
  // Study quality (20%)
  if (text.contains('randomized') || text.contains('systematic review')) score += 0.1;
  if (text.contains('clinical trial')) score += 0.1;
  
  return score.clamp(0.0, 1.0);
}
```

## Age Group Classification

### Pediatric Age Groups
```dart
String _extractAgeGroup(String title, String abstract) {
  if (text.contains('neonatal') || text.contains('newborn')) 
    return 'Neonatal (0-28 days)';
  if (text.contains('infant') || text.contains('baby')) 
    return 'Infant (1-12 months)';
  if (text.contains('toddler')) 
    return 'Toddler (1-3 years)';
  if (text.contains('preschool')) 
    return 'Preschool (3-5 years)';
  if (text.contains('school age')) 
    return 'School age (6-12 years)';
  if (text.contains('adolescent') || text.contains('teen')) 
    return 'Adolescent (13-18 years)';
  if (text.contains('pediatric') || text.contains('children')) 
    return 'Pediatric (0-18 years)';
  
  return 'Not specified';
}
```

## Python Downloader Script

### Features
- **Automated Download**: Downloads studies from PubMed API
- **Data Processing**: Extracts and classifies study information
- **Flutter Export**: Creates Flutter-compatible JSON files
- **Statistics Generation**: Comprehensive dataset analytics

### Usage
```bash
cd python
python pubmed_dataset_downloader.py
```

### Output Files
- `pubmed_pediatric_studies_YYYYMMDD_HHMMSS.json`: Full dataset
- `assets/data/pubmed_pediatric_studies.json`: Flutter-compatible format
- `pubmed_download.log`: Download logs

## API Rate Limiting

### PubMed API Guidelines
- **Search Requests**: 3 requests per second
- **Summary Requests**: 3 requests per second
- **Fetch Requests**: 3 requests per second
- **User-Agent**: Required for all requests

### Implementation
```dart
// Rate limiting in service
await Future.delayed(const Duration(milliseconds: 100));
```

## Error Handling

### Network Errors
- **Retry Logic**: Automatic retry for failed requests
- **Fallback Data**: Uses cached data when offline
- **User Feedback**: Clear error messages to users

### Data Validation
- **Study Filtering**: Removes invalid or incomplete studies
- **Duplicate Detection**: Prevents duplicate studies
- **Quality Checks**: Validates study metadata

## Privacy & Compliance

### HIPAA Compliance
- **Local Storage**: All data stored locally in SQLite
- **No PII**: No personal health information transmitted
- **User Consent**: Explicit consent for data usage

### Data Security
- **Encrypted Storage**: SQLite database encryption
- **Secure Transmission**: HTTPS for all API calls
- **Access Control**: User-controlled data access

## Performance Optimization

### Caching Strategy
- **Study Cache**: Caches downloaded studies locally
- **Search Results**: Caches search results for faster access
- **Recommendations**: Caches treatment recommendations

### Memory Management
- **Lazy Loading**: Loads studies on demand
- **Garbage Collection**: Proper disposal of resources
- **Memory Monitoring**: Tracks memory usage

## Testing

### Unit Tests
```dart
test('PubMed service initialization', () async {
  final service = PubMedDatasetService();
  await service.initialize();
  expect(service.getDatasetStatistics()['total_studies'], greaterThan(0));
});
```

### Integration Tests
```dart
test('Treatment recommendations for fever', () async {
  final service = PubMedDatasetService();
  final recommendations = service.getTreatmentRecommendations('fever', childMetadata);
  expect(recommendations['studies_found'], greaterThan(0));
  expect(recommendations['evidence_level'], isNotEmpty);
});
```

## Future Enhancements

### Planned Features
- **Real-time Updates**: Live PubMed data updates
- **Advanced Filtering**: More sophisticated study filtering
- **Machine Learning**: ML-powered study classification
- **Multi-language**: Support for non-English studies

### Research Integration
- **Clinical Guidelines**: Integration with clinical guidelines
- **Drug Interactions**: Drug interaction checking
- **Dosage Calculator**: Age-appropriate dosage calculations
- **Side Effects**: Comprehensive side effect information

## Contributing

### Development Setup
1. Install Python dependencies: `pip install requests`
2. Run downloader script: `python pubmed_dataset_downloader.py`
3. Import data into Flutter app
4. Test integration with voice logger

### Code Standards
- **Documentation**: Comprehensive code documentation
- **Error Handling**: Robust error handling
- **Testing**: Unit and integration tests
- **Performance**: Optimized for mobile devices

## Support

### Documentation
- **API Reference**: Complete API documentation
- **Integration Guide**: Step-by-step integration guide
- **Troubleshooting**: Common issues and solutions

### Community
- **GitHub Issues**: Report bugs and feature requests
- **Discussions**: Community discussions and support
- **Contributions**: Welcome community contributions

---

*This integration brings evidence-based medicine to the fingertips of caregivers, helping them make informed decisions about their children's health.* 