import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'logging_service.dart';

/// Hybrid Learning Pipeline Service
/// Collects data from cloud AI interactions to continuously improve local models
class LearningPipelineService {
  static LearningPipelineService? _instance;
  static LearningPipelineService get instance => _instance ??= LearningPipelineService._internal();

  LearningPipelineService._internal();

  final AppConfig _config = AppConfig.instance;
  final LoggingService _loggingService = LoggingService();
  
  // Learning data storage
  final String _learningDataDir = 'learning_data';
  final String _interactionsFile = 'user_interactions.jsonl';
  final String _modelPerformanceFile = 'model_performance.json';
  
  // Learning thresholds
  final int _minSamplesForTraining = 1000; // Minimum samples before training
  final int _maxDataAge = 30; // Days to keep data
  final double _qualityThreshold = 0.85; // Minimum quality to use local model
  
  // Current learning state
  bool _isLearningEnabled = true;
  bool _isTrainingInProgress = false;
  DateTime? _lastTrainingDate;
  Map<String, double> _modelPerformance = {};
  
  /// Initialize the learning pipeline
  Future<bool> initialize() async {
    try {
      // Create learning data directory
      final dir = Directory(_learningDataDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Load existing performance data
      await _loadModelPerformance();
      
      print('✅ Learning pipeline initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing learning pipeline: $e');
      return false;
    }
  }
  
  /// Collect learning data from cloud AI interaction
  Future<void> collectInteractionData({
    required String userInput,
    required Map<String, dynamic> cloudAIResponse,
    required String cloudProvider, // 'grok' or 'openai'
    required Map<String, dynamic> userFeedback, // User satisfaction, follow-up questions, etc.
    required Map<String, dynamic> childContext, // Age, gender, medical history
  }) async {
    if (!_isLearningEnabled) return;
    
    try {
      final interaction = {
        'timestamp': DateTime.now().toIso8601String(),
        'user_input': userInput,
        'cloud_ai_response': cloudAIResponse,
        'cloud_provider': cloudProvider,
        'user_feedback': userFeedback,
        'child_context': childContext,
        'interaction_id': _generateInteractionId(),
        'quality_score': _calculateQualityScore(cloudAIResponse, userFeedback),
      };
      
      // Store interaction data
      await _storeInteractionData(interaction);
      
      // Check if we have enough data for training
      await _checkTrainingThreshold();
      
      print('📚 Learning data collected: ${interaction['interaction_id']}');
    } catch (e) {
      print('❌ Error collecting learning data: $e');
    }
  }
  
  /// Store interaction data for learning
  Future<void> _storeInteractionData(Map<String, dynamic> interaction) async {
    try {
      final file = File(path.join(_learningDataDir, _interactionsFile));
      
      // Append to JSONL file (one JSON object per line)
      final line = jsonEncode(interaction) + '\n';
      await file.writeAsString(line, mode: FileMode.append);
      
      // Clean old data
      await _cleanOldData();
    } catch (e) {
      print('❌ Error storing interaction data: $e');
    }
  }
  
  /// Calculate quality score for learning data
  double _calculateQualityScore(Map<String, dynamic> aiResponse, Map<String, dynamic> userFeedback) {
    double score = 0.0;
    
    // Response completeness
    if (aiResponse['symptoms'] != null) score += 0.3;
    if (aiResponse['follow_up_questions'] != null) score += 0.2;
    if (aiResponse['immediate_advice'] != null) score += 0.2;
    if (aiResponse['seek_care_when'] != null) score += 0.2;
    
    // User satisfaction (if available)
    if (userFeedback['satisfaction'] != null) {
      score += (userFeedback['satisfaction'] as double) * 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Check if we have enough data for training
  Future<void> _checkTrainingThreshold() async {
    try {
      final file = File(path.join(_learningDataDir, _interactionsFile));
      if (!await file.exists()) return;
      
      final lines = await file.readAsLines();
      final validLines = lines.where((line) => line.trim().isNotEmpty).length;
      
      if (validLines >= _minSamplesForTraining && !_isTrainingInProgress) {
        print('🎯 Training threshold reached: $validLines samples');
        await _triggerModelTraining();
      }
    } catch (e) {
      print('❌ Error checking training threshold: $e');
    }
  }
  
  /// Trigger model training in background
  Future<void> _triggerModelTraining() async {
    if (_isTrainingInProgress) return;
    
    try {
      _isTrainingInProgress = true;
      print('🚀 Starting background model training...');
      
      // This would call a Python training script
      // For now, we'll simulate the process
      await _simulateModelTraining();
      
      _lastTrainingDate = DateTime.now();
      _isTrainingInProgress = false;
      
      print('✅ Background model training completed');
    } catch (e) {
      print('❌ Error in model training: $e');
      _isTrainingInProgress = false;
    }
  }
  
  /// Simulate model training (replace with actual Python call)
  Future<void> _simulateModelTraining() async {
    // Simulate training time
    await Future.delayed(const Duration(seconds: 5));
    
    // Simulate performance improvement
    _modelPerformance['symptom_extraction'] = 0.82;
    _modelPerformance['risk_assessment'] = 0.78;
    _modelPerformance['follow_up_questions'] = 0.75;
    
    // Save performance data
    await _saveModelPerformance();
  }
  
  /// Get current model performance
  Map<String, double> get modelPerformance => _modelPerformance;
  
  /// Check if local models are ready for production
  bool get areLocalModelsReady {
    if (_modelPerformance.isEmpty) return false;
    
    // Check if any model meets quality threshold
    return _modelPerformance.values.any((score) => score >= _qualityThreshold);
  }
  
  /// Get recommended model usage (cloud vs local)
  String get recommendedModelUsage {
    if (!areLocalModelsReady) return 'cloud_only';
    
    final bestLocalScore = _modelPerformance.values.reduce((a, b) => a > b ? a : b);
    
    if (bestLocalScore >= 0.95) return 'local_primary';
    if (bestLocalScore >= 0.90) return 'local_secondary';
    if (bestLocalScore >= 0.85) return 'hybrid';
    
    return 'cloud_primary';
  }
  
  /// Clean old learning data
  Future<void> _cleanOldData() async {
    try {
      final file = File(path.join(_learningDataDir, _interactionsFile));
      if (!await file.exists()) return;
      
      final lines = await file.readAsLines();
      final cutoffDate = DateTime.now().subtract(Duration(days: _maxDataAge));
      
      final validLines = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final data = jsonDecode(line);
          final timestamp = DateTime.parse(data['timestamp']);
          
          if (timestamp.isAfter(cutoffDate)) {
            validLines.add(line);
          }
        } catch (e) {
          // Skip invalid lines
          continue;
        }
      }
      
      // Rewrite file with only recent data
      await file.writeAsString(validLines.join('\n') + '\n');
      
      print('🧹 Cleaned old learning data: ${lines.length - validLines.length} records removed');
    } catch (e) {
      print('❌ Error cleaning old data: $e');
    }
  }
  
  /// Generate unique interaction ID
  String _generateInteractionId() {
    return 'int_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 1000))}';
  }
  
  /// Load model performance data
  Future<void> _loadModelPerformance() async {
    try {
      final file = File(path.join(_learningDataDir, _modelPerformanceFile));
      if (await file.exists()) {
        final content = await file.readAsString();
        _modelPerformance = Map<String, double>.from(jsonDecode(content));
      }
    } catch (e) {
      print('❌ Error loading model performance: $e');
    }
  }
  
  /// Save model performance data
  Future<void> _saveModelPerformance() async {
    try {
      final file = File(path.join(_learningDataDir, _modelPerformanceFile));
      await file.writeAsString(jsonEncode(_modelPerformance));
    } catch (e) {
      print('❌ Error saving model performance: $e');
    }
  }
  
  /// Get learning pipeline status
  Map<String, dynamic> getStatus() {
    return {
      'is_learning_enabled': _isLearningEnabled,
      'is_training_in_progress': _isTrainingInProgress,
      'last_training_date': _lastTrainingDate?.toIso8601String(),
      'model_performance': _modelPerformance,
      'are_local_models_ready': areLocalModelsReady,
      'recommended_usage': recommendedModelUsage,
      'learning_data_count': _getLearningDataCount(),
    };
  }
  
  /// Get count of learning data samples
  int _getLearningDataCount() {
    try {
      final file = File(path.join(_learningDataDir, _interactionsFile));
      if (file.existsSync()) {
        return file.readAsLinesSync().where((line) => line.trim().isNotEmpty).length;
      }
    } catch (e) {
      // Ignore errors
    }
    return 0;
  }
}
