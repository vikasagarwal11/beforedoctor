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
  
  // Add TextEditingController as class field
  final TextEditingController _searchController = TextEditingController();

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
            _buildStatRow('Pediatric Studies', _statistics['pediatric_studies'].toString()),
            _buildStatRow('Treatment Studies', _statistics['treatment_studies'].toString()),
            _buildStatRow('Age Range', _statistics['age_range'] ?? 'N/A'),
            _buildStatRow('Last Updated', _statistics['last_updated'] ?? 'N/A'),
          ] else ...[
            const Text('No statistics available'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
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
            ..._recentStudies.map((study) => _buildStudyItem(study)),
          ] else ...[
            const Text('No recent studies available'),
          ],
        ],
      ),
    );
  }

  Widget _buildStudyItem(Map<String, dynamic> study) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            study['title'] ?? 'Untitled Study',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            study['authors'] ?? 'Unknown Authors',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getEvidenceColor(study['evidence_level']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  study['evidence_level'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                study['year']?.toString() ?? 'Unknown Year',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEvidenceColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
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
            controller: _searchController,
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
                  final text = _searchController.text;
                  if (text.isNotEmpty) {
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

  Widget _buildTreatmentRecommendationsCard() {
    if (_treatmentRecommendations.isEmpty) {
      return const SizedBox.shrink();
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
                  '💊 Treatment Recommendations for "$_selectedSymptom"',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationRow('Studies Found', _treatmentRecommendations['studies_found'].toString()),
          _buildRecommendationRow('Evidence Level', _treatmentRecommendations['evidence_level'] ?? 'N/A'),
          if (_treatmentRecommendations['treatments'] != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Common Treatments:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...(_treatmentRecommendations['treatments'] as List).take(3).map((treatment) => 
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('• $treatment'),
              )
            ),
          ],
          if (_treatmentRecommendations['age_considerations'] != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Age Considerations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...(_treatmentRecommendations['age_considerations'] as List).take(2).map((consideration) => 
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('• $consideration'),
              )
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(value),
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
    // Proper disposal of TextEditingController
    _searchController.dispose();
    _characterEngine.dispose();
    super.dispose();
  }
} 