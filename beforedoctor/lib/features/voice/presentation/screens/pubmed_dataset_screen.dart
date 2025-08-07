import 'package:flutter/material.dart';
import '../../../../services/pubmed_dataset_service.dart';
import '../../../../core/services/character_interaction_engine.dart';
import 'package:logger/logger.dart';

class PubMedDatasetScreen extends StatefulWidget {
  const PubMedDatasetScreen({Key? key}) : super(key: key);

  @override
  State<PubMedDatasetScreen> createState() => _PubMedDatasetScreenState();
}

class _PubMedDatasetScreenState extends State<PubMedDatasetScreen> {
  final PubMedDatasetService _pubmedService = PubMedDatasetService();
  final CharacterInteractionEngine _characterEngine = CharacterInteractionEngine.instance;
  final Logger _logger = Logger();

  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _recentStudies = [];
  bool _isLoading = false;
  String _selectedSymptom = '';
  Map<String, dynamic> _treatmentRecommendations = {};

  @override
  void initState() {
    super.initState();
    _loadDatasetInformation();
  }

  Future<void> _loadDatasetInformation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _pubmedService.initialize();
      final stats = _pubmedService.getDatasetStatistics();
      final studies = _pubmedService.getRelevantStudies('fever'); // Default to fever studies
      
      setState(() {
        _statistics = stats;
        _recentStudies = studies.take(5).toList();
        _isLoading = false;
      });

      _logger.i('📊 PubMed dataset information loaded');
    } catch (e) {
      _logger.e('❌ Failed to load PubMed dataset: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchTreatmentRecommendations(String symptom) async {
    if (symptom.isEmpty) return;

    setState(() {
      _isLoading = true;
      _selectedSymptom = symptom;
    });

    try {
      // Mock child metadata for demonstration
      final childMetadata = {
        'child_age': '4',
        'child_gender': 'male',
        'child_weight_kg': '16.5',
        'child_height_cm': '105',
      };

      final recommendations = _pubmedService.getTreatmentRecommendations(symptom, childMetadata);
      
      setState(() {
        _treatmentRecommendations = recommendations;
        _isLoading = false;
      });

      // Character reaction
      _characterEngine.reactToSymptom(symptom);
      await _characterEngine.speakWithAnimation(
        'I found ${recommendations['studies_found']} relevant studies for $symptom. '
        'The evidence level is ${recommendations['evidence_level']}.'
      );

      _logger.i('🔍 Treatment recommendations loaded for: $symptom');
    } catch (e) {
      _logger.e('❌ Failed to get treatment recommendations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: Colors.blue[600], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '📊 Dataset Statistics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_statistics.isNotEmpty) ...[
            _buildStatRow('Total Studies', _statistics['total_studies'].toString()),
            const SizedBox(height: 12),
            const Text(
              'Study Types:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_statistics['study_types'] as Map<String, int>).entries.map(
              (entry) => _buildStatRow(entry.key, entry.value.toString()),
            ),
            const SizedBox(height: 12),
            const Text(
              'Age Groups:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_statistics['age_groups'] as Map<String, int>).entries.map(
              (entry) => _buildStatRow(entry.key, entry.value.toString()),
            ),
          ] else ...[
            const Text('No statistics available'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStudiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.science, color: Colors.green[600], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '🔬 Recent Studies',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentStudies.isNotEmpty) ...[
            ..._recentStudies.map((study) => _buildStudyCard(study)),
          ] else ...[
            const Text('No recent studies available'),
          ],
        ],
      ),
    );
  }

  Widget _buildStudyCard(Map<String, dynamic> study) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            study['title'] ?? 'No title',
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  study['study_type'] ?? 'Unknown',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Score: ${(study['relevance_score'] as double).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (study['symptom_focus'] != null && (study['symptom_focus'] as List).isNotEmpty) ...[
            Text(
              'Symptoms: ${(study['symptom_focus'] as List).join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTreatmentRecommendationsCard() {
    if (_treatmentRecommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medical_services, color: Colors.orange[600], size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  '💊 Treatment Recommendations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Search for a symptom to get treatment recommendations'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medical_services, color: Colors.orange[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💊 Treatment for: $_selectedSymptom',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Evidence level
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getEvidenceLevelColor(_treatmentRecommendations['evidence_level']),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Evidence Level: ${_treatmentRecommendations['evidence_level']}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          
          // Studies found
          Text(
            'Studies Found: ${_treatmentRecommendations['studies_found']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Treatments
          if (_treatmentRecommendations['treatments'] != null && 
              (_treatmentRecommendations['treatments'] as List).isNotEmpty) ...[
            const Text(
              'Common Treatments:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_treatmentRecommendations['treatments'] as List).map(
              (treatment) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Text(treatment),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Recommendations
          if (_treatmentRecommendations['recommendations'] != null && 
              (_treatmentRecommendations['recommendations'] as List).isNotEmpty) ...[
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_treatmentRecommendations['recommendations'] as List).map(
              (rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rec)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Cautions
          if (_treatmentRecommendations['cautions'] != null && 
              (_treatmentRecommendations['cautions'] as List).isNotEmpty) ...[
            const Text(
              'Cautions:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...(_treatmentRecommendations['cautions'] as List).map(
              (caution) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(caution, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getEvidenceLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'strong':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'limited':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSymptomSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.search, color: Colors.purple[600], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '🔍 Search Symptoms',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter symptom (e.g., fever, cough, vomiting)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
                onPressed: _isLoading ? null : () {
                  final text = (context.findRenderObject() as RenderBox?)
                      ?.findChild<EditableText>()
                      ?.controller
                      ?.text;
                  if (text != null && text.isNotEmpty) {
                    _searchTreatmentRecommendations(text);
                  }
                },
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _searchTreatmentRecommendations(value);
              }
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Common symptoms: fever, cough, vomiting, diarrhea, rash, pain, headache',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.science, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                "PubMed Dataset",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDatasetInformation,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading PubMed dataset...'),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSymptomSearchCard(),
              const SizedBox(height: 20),
              _buildTreatmentRecommendationsCard(),
              const SizedBox(height: 20),
              _buildStatisticsCard(),
              const SizedBox(height: 20),
              _buildRecentStudiesCard(),
              const SizedBox(height: 20),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _characterEngine.dispose();
    super.dispose();
  }
} 