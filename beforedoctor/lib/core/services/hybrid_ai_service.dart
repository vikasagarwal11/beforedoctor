import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../config/app_config.dart';
import 'learning_pipeline_service.dart';
import 'logging_service.dart';

/// Hybrid AI Service
/// Intelligently switches between cloud AI and local trained models
class HybridAIService {
  static HybridAIService? _instance;
  static HybridAIService get instance => _instance ??= HybridAIService._internal();

  HybridAIService._internal();

  final AppConfig _config = AppConfig.instance;
  final LearningPipelineService _learningPipeline = LearningPipelineService.instance;
  final LoggingService _loggingService = LoggingService();
  
  // Model usage strategy
  String _currentStrategy = 'cloud_primary'; // cloud_primary, hybrid, local_primary
  Map<String, double> _localModelPerformance = {};
  
  // Performance tracking
  final Map<String, List<double>> _responseQuality = {
    'cloud': [],
    'local': [],
  };
  
  /// Initialize the hybrid service
  Future<bool> initialize() async {
    try {
      // Initialize learning pipeline
      await _learningPipeline.initialize();
      
      // Load local model performance
      await _loadLocalModelPerformance();
      
      // Determine current strategy
      _updateStrategy();
      
      print('✅ Hybrid AI service initialized successfully');
      print('🎯 Current strategy: $_currentStrategy');
      
      return true;
    } catch (e) {
      print('❌ Error initializing hybrid AI service: $e');
      return false;
    }
  }
  
  /// Process voice input using hybrid approach
  Future<Map<String, dynamic>> processVoiceInput({
    required String userInput,
    required Map<String, dynamic> childContext,
  }) async {
    try {
      final startTime = DateTime.now();
      Map<String, dynamic> result;
      String methodUsed;
      
      // Determine which method to use based on strategy
      switch (_currentStrategy) {
        case 'cloud_primary':
          result = await _processWithCloudAI(userInput, childContext);
          methodUsed = 'cloud_primary';
          break;
          
        case 'hybrid':
          result = await _processWithHybrid(userInput, childContext);
          methodUsed = 'hybrid';
          break;
          
        case 'local_primary':
          result = await _processWithLocalModels(userInput, childContext);
          methodUsed = 'local_primary';
          break;
          
        default:
          result = await _processWithCloudAI(userInput, childContext);
          methodUsed = 'cloud_fallback';
      }
      
      // Calculate response time
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      // Collect learning data
      await _collectLearningData(
        userInput: userInput,
        result: result,
        methodUsed: methodUsed,
        responseTime: responseTime,
        childContext: childContext,
      );
      
      // Update strategy based on performance
      await _updateStrategyBasedOnPerformance();
      
      return result;
      
    } catch (e) {
      print('❌ Error in hybrid AI processing: $e');
      // Fallback to cloud AI
      return await _processWithCloudAI(userInput, childContext);
    }
  }
  
  /// Process with cloud AI (Grok/OpenAI)
  Future<Map<String, dynamic>> _processWithCloudAI(
    String userInput, 
    Map<String, dynamic> childContext
  ) async {
    try {
      print('☁️ Processing with cloud AI...');
      
      // Use existing cloud AI logic
      // This would call your current Grok/OpenAI implementation
      
      // Simulate cloud AI response for now
      final response = await _simulateCloudAIResponse(userInput, childContext);
      
      return response;
      
    } catch (e) {
      print('❌ Cloud AI failed: $e');
      rethrow;
    }
  }
  
  /// Process with local trained models
  Future<Map<String, dynamic>> _processWithLocalModels(
    String userInput, 
    Map<String, dynamic> childContext
  ) async {
    try {
      print('🏠 Processing with local models...');
      
      // Check if local models are available
      if (!_learningPipeline.areLocalModelsReady) {
        print('⚠️ Local models not ready, falling back to cloud');
        return await _processWithCloudAI(userInput, childContext);
      }
      
      // Use local models for different tasks
      final result = await _useLocalModels(userInput, childContext);
      
      return result;
      
    } catch (e) {
      print('❌ Local models failed: $e');
      // Fallback to cloud AI
      return await _processWithCloudAI(userInput, childContext);
    }
  }
  
  /// Process with hybrid approach (local + cloud)
  Future<Map<String, dynamic>> _processWithHybrid(
    String userInput, 
    Map<String, dynamic> childContext
  ) async {
    try {
      print('🔄 Processing with hybrid approach...');
      
      // Try local models first for basic tasks
      Map<String, dynamic> localResult;
      try {
        localResult = await _useLocalModels(userInput, childContext);
      } catch (e) {
        print('⚠️ Local models failed in hybrid mode: $e');
        localResult = {};
      }
      
      // Use cloud AI for complex reasoning and enhancement
      final cloudResult = await _processWithCloudAI(userInput, childContext);
      
      // Combine results intelligently
      final hybridResult = _combineResults(localResult, cloudResult);
      
      return hybridResult;
      
    } catch (e) {
      print('❌ Hybrid processing failed: $e');
      return await _processWithCloudAI(userInput, childContext);
    }
  }
  
  /// Use local trained models for specific tasks
  Future<Map<String, dynamic>> _useLocalModels(
    String userInput, 
    Map<String, dynamic> childContext
  ) async {
    try {
      final result = <String, dynamic>{
        'transcription': userInput,
        'api_used': 'local_models',
        'confidence': 0.0,
      };
      
      // Use local symptom classifier if available
      if (_localModelPerformance.containsKey('symptom_extraction')) {
        final symptoms = await _classifySymptomsLocally(userInput);
        result['symptoms'] = symptoms;
        result['confidence'] = _localModelPerformance['symptom_extraction'] ?? 0.0;
      }
      
      // Use local risk assessor if available
      if (_localModelPerformance.containsKey('risk_assessment')) {
        final riskAssessment = await _assessRiskLocally(userInput, childContext);
        result['risk_level'] = riskAssessment['risk_level'];
        result['severity'] = riskAssessment['severity'];
      }
      
      // Use local follow-up generator if available
      if (_localModelPerformance.containsKey('follow_up_questions')) {
        final followUps = await _generateFollowUpsLocally(userInput, childContext);
        result['follow_up_questions'] = followUps;
      }
      
      return result;
      
    } catch (e) {
      print('❌ Error using local models: $e');
      rethrow;
    }
  }
  
  /// Classify symptoms using local model
  Future<List<String>> _classifySymptomsLocally(String userInput) async {
    try {
      // This would load and use the trained symptom classifier
      // For now, return basic keyword-based extraction
      
      final symptoms = <String>[];
      final lowerInput = userInput.toLowerCase();
      
      // Basic symptom keywords (this would be replaced by the trained model)
      final symptomKeywords = {
        'fever': ['fever', 'temperature', 'hot', 'burning up', 'temp'],
        'cough': ['cough', 'coughing', 'hack', 'chest'],
        'pain': ['pain', 'hurts', 'ache', 'sore', 'hurt'],
        'vomiting': ['vomit', 'throw up', 'sick', 'nausea'],
        'diarrhea': ['diarrhea', 'loose stool', 'runny', 'stomach'],
      };
      
      for (final entry in symptomKeywords.entries) {
        final symptom = entry.key;
        final keywords = entry.value;
        
        for (final keyword in keywords) {
          if (lowerInput.contains(keyword)) {
            symptoms.add(symptom);
            break;
          }
        }
      }
      
      return symptoms;
      
    } catch (e) {
      print('❌ Error in local symptom classification: $e');
      return [];
    }
  }
  
  /// Assess risk using local model
  Future<Map<String, dynamic>> _assessRiskLocally(
    String userInput, 
    Map<String, dynamic> childContext
  ) async {
    try {
      // This would use the trained risk assessment model
      // For now, return basic assessment
      
      final age = childContext['child_age'] ?? 5;
      final symptoms = await _classifySymptomsLocally(userInput);
      
      // Basic risk logic (would be replaced by trained model)
      String riskLevel = 'low';
      String severity = 'mild';
      
      if (symptoms.contains('fever') && age < 3) {
        riskLevel = 'medium';
        severity = 'moderate';
      }
      
      if (symptoms.contains('breathing_difficulty')) {
        riskLevel = 'high';
        severity = 'severe';
      }
      
      return {
        'risk_level': riskLevel,
        'severity': severity,
        'confidence': _localModelPerformance['risk_assessment'] ?? 0.0,
      };
      
    } catch (e) {
      print('❌ Error in local risk assessment: $e');
      return {'risk_level': 'unknown', 'severity': 'unknown', 'confidence': 0.0};
    }
  }
  
  /// Generate follow-up questions using local model
  Future<List<String>> _generateFollowUpsLocally(
    String userInput, 
    Map<String, dynamic> childContext
  ) async {
    try {
      // This would use the trained follow-up question model
      // For now, return basic questions
      
      final symptoms = await _classifySymptomsLocally(userInput);
      final age = childContext['child_age'] ?? 5;
      
      final questions = <String>[];
      
      if (symptoms.contains('fever')) {
        questions.add('How high is the fever?');
        questions.add('When did the fever start?');
        questions.add('Any other symptoms with the fever?');
      }
      
      if (symptoms.contains('pain')) {
        questions.add('Where exactly is the pain?');
        questions.add('How severe is the pain (1-10)?');
        questions.add('What makes the pain better or worse?');
      }
      
      if (age < 3) {
        questions.add('Is your child eating and drinking normally?');
        questions.add('Any changes in behavior or activity level?');
      }
      
      return questions;
      
    } catch (e) {
      print('❌ Error in local follow-up generation: $e');
      return [];
    }
  }
  
  /// Combine local and cloud results intelligently
  Map<String, dynamic> _combineResults(
    Map<String, dynamic> localResult, 
    Map<String, dynamic> cloudResult
  ) {
    try {
      final combined = <String, dynamic>{};
      
      // Use local results where available and confident
      for (final entry in localResult.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value != null && value.toString().isNotEmpty) {
          combined[key] = value;
        }
      }
      
      // Enhance with cloud results
      for (final entry in cloudResult.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // Don't override local results unless cloud is significantly better
        if (!combined.containsKey(key) || 
            (key == 'confidence' && value > (combined[key] ?? 0.0))) {
          combined[key] = value;
        }
      }
      
      // Mark as hybrid result
      combined['api_used'] = 'hybrid';
      combined['local_confidence'] = localResult['confidence'] ?? 0.0;
      combined['cloud_confidence'] = cloudResult['confidence'] ?? 0.0;
      
      return combined;
      
    } catch (e) {
      print('❌ Error combining results: $e');
      return cloudResult; // Fallback to cloud result
    }
  }
  
  /// Simulate cloud AI response (replace with actual implementation)
  Future<Map<String, dynamic>> _simulateCloudAIResponse(
    String userInput, 
    Map<String, dynamic> childContext
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'symptoms': ['back_pain', 'muscle_pain'],
      'severity': 'medium',
      'risk_level': 'low',
      'assessment': 'Possible muscle strain or posture issue',
      'follow_up_questions': [
        'How long has the pain been present?',
        'Did this start after any specific activity?',
        'Is the pain worse with movement?',
        'Any numbness or tingling?',
        'Any recent falls or injuries?'
      ],
      'immediate_advice': 'Rest, avoid heavy lifting, apply ice/heat',
      'seek_care_when': 'If pain persists >3 days or worsens',
      'confidence': 0.95,
      'api_used': 'cloud_simulation',
    };
  }
  
  /// Collect learning data for continuous improvement
  Future<void> _collectLearningData({
    required String userInput,
    required Map<String, dynamic> result,
    required String methodUsed,
    required int responseTime,
    required Map<String, dynamic> childContext,
  }) async {
    try {
      // Simulate user feedback (in real app, this would come from user interaction)
      final userFeedback = {
        'satisfaction': 0.9, // User satisfaction score
        'response_time': responseTime,
        'method_used': methodUsed,
      };
      
      // Determine which cloud provider was used
      final cloudProvider = result['api_used']?.toString().contains('cloud') == true 
          ? 'openai' // Default to OpenAI for simulation
          : 'local';
      
      // Collect data for learning
      await _learningPipeline.collectInteractionData(
        userInput: userInput,
        cloudAIResponse: result,
        cloudProvider: cloudProvider,
        userFeedback: userFeedback,
        childContext: childContext,
      );
      
    } catch (e) {
      print('❌ Error collecting learning data: $e');
    }
  }
  
  /// Update strategy based on performance
  Future<void> _updateStrategyBasedOnPerformance() async {
    try {
      // Get current learning pipeline status
      final status = _learningPipeline.getStatus();
      
      // Update local model performance
      _localModelPerformance = status['model_performance'] ?? {};
      
      // Update strategy
      _updateStrategy();
      
    } catch (e) {
      print('❌ Error updating strategy: $e');
    }
  }
  
  /// Update the current strategy
  void _updateStrategy() {
    final recommendedUsage = _learningPipeline.recommendedModelUsage;
    
    switch (recommendedUsage) {
      case 'cloud_only':
        _currentStrategy = 'cloud_primary';
        break;
      case 'hybrid':
        _currentStrategy = 'hybrid';
        break;
      case 'local_primary':
        _currentStrategy = 'local_primary';
        break;
      case 'local_secondary':
        _currentStrategy = 'hybrid';
        break;
      default:
        _currentStrategy = 'cloud_primary';
    }
    
    print('🎯 Strategy updated to: $_currentStrategy');
  }
  
  /// Load local model performance data
  Future<void> _loadLocalModelPerformance() async {
    try {
      final status = _learningPipeline.getStatus();
      _localModelPerformance = status['model_performance'] ?? {};
    } catch (e) {
      print('❌ Error loading local model performance: $e');
    }
  }
  
  /// Get current service status
  Map<String, dynamic> getStatus() {
    return {
      'current_strategy': _currentStrategy,
      'local_model_performance': _localModelPerformance,
      'learning_pipeline_status': _learningPipeline.getStatus(),
      'response_quality': _responseQuality,
    };
  }
  
  /// Get recommended usage strategy
  String get recommendedStrategy => _currentStrategy;
  
  /// Check if local models are available
  bool get areLocalModelsAvailable => _learningPipeline.areLocalModelsReady;
}
