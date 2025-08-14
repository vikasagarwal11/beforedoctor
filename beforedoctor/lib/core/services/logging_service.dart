import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  // Initialize logger with structured output
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: Level.debug,
  );

  // HIPAA-compliant logging (no PII)
  Future<void> logInteraction({
    required String interactionType,
    required String symptomCategory,
    required String modelUsed,
    required int responseTime,
    required bool success,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    
    // Create HIPAA-compliant log entry (no personal data)
    final logData = {
      'timestamp': timestamp,
      'interaction_type': interactionType, // 'voice_log', 'ai_response', 'symptom_detection'
      'symptom_category': symptomCategory, // 'fever', 'cough', 'rash', etc.
      'model_used': modelUsed, // 'openai', 'grok', 'fallback'
      'response_time_ms': responseTime,
      'success': success,
      'error_message': errorMessage,
      'metadata': metadata, // Additional non-PII data
    };

    // Console logging for development
    _logger.i('AI_INTERACTION: ${logData.toString()}');

    // File logging for analytics (HIPAA-compliant)
    await _writeToLogFile(logData);
  }

  // Log AI performance metrics
  Future<void> logAIPerformance({
    required String model,
    required int latency,
    required bool success,
    required String promptType,
  }) async {
    await logInteraction(
      interactionType: 'ai_performance',
      symptomCategory: 'general',
      modelUsed: model,
      responseTime: latency,
      success: success,
      metadata: {
        'prompt_type': promptType,
        'model_version': 'latest',
      },
    );
  }

  // Log symptom detection
  Future<void> logSymptomDetection({
    required String symptom,
    required String ageGroup,
    required bool detected,
    required double confidence,
  }) async {
    await logInteraction(
      interactionType: 'symptom_detection',
      symptomCategory: symptom,
      modelUsed: 'voice_processor',
      responseTime: 0,
      success: detected,
      metadata: {
        'age_group': ageGroup,
        'confidence': confidence,
        'detection_method': 'keyword_matching',
      },
    );
  }

  // Log user interaction patterns
  Future<void> logUserInteraction({
    required String action,
    required String screen,
    required int duration,
  }) async {
    await logInteraction(
      interactionType: 'user_interaction',
      symptomCategory: 'general',
      modelUsed: 'none',
      responseTime: duration,
      success: true,
      metadata: {
        'action': action, // 'button_press', 'voice_input', 'model_selection'
        'screen': screen, // 'voice_logger', 'settings', 'home'
      },
    );
  }

  // Private method to write to log file
  Future<void> _writeToLogFile(Map<String, dynamic> logData) async {
    try {
      final logFile = File('logs/beforedoctor_analytics.log');
      
      // Create logs directory if it doesn't exist
      final logsDir = Directory('logs');
      if (!await logsDir.exists()) {
        await logsDir.create();
      }

      // Append log entry with timestamp
      final logEntry = '${DateTime.now().toIso8601String()}: ${logData.toString()}\n';
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      _logger.e('Error writing to log file: $e');
    }
  }

  // Get analytics summary (for dashboard)
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final logFile = File('logs/beforedoctor_analytics.log');
      if (!await logFile.exists()) {
        return {
          'total_interactions': 0,
          'success_rate': 0.0,
          'avg_response_time': 0,
          'most_common_symptoms': [],
          'model_performance': {},
        };
      }

      final lines = await logFile.readAsLines();
      final interactions = <Map<String, dynamic>>[];
      
      for (final line in lines) {
        try {
          final dataStart = line.indexOf('{');
          if (dataStart != -1) {
            final jsonStr = line.substring(dataStart);
            final data = Map<String, dynamic>.from(
              // Simple parsing for demo - in production use proper JSON parsing
              Map.fromEntries(
                jsonStr.replaceAll('{', '').replaceAll('}', '').split(',')
                    .map((e) => e.trim().split(':'))
                    .where((e) => e.length == 2)
                    .map((e) => MapEntry(e[0].trim(), e[1].trim()))
              )
            );
            interactions.add(data);
          }
        } catch (e) {
          // Skip malformed lines
          continue;
        }
      }

      // Calculate analytics
      final totalInteractions = interactions.length;
      final successfulInteractions = interactions.where((i) => i['success'] == true).length;
      final successRate = totalInteractions > 0 ? successfulInteractions / totalInteractions : 0.0;
      
      final responseTimes = interactions
          .where((i) => i['response_time_ms'] != null)
          .map((i) => int.tryParse(i['response_time_ms'].toString()) ?? 0)
          .toList();
      final avgResponseTime = responseTimes.isNotEmpty 
          ? responseTimes.reduce((a, b) => a + b) / responseTimes.length 
          : 0;

      final symptomCounts = <String, int>{};
      for (final interaction in interactions) {
        final symptom = interaction['symptom_category']?.toString() ?? 'unknown';
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
      final mostCommonSymptoms = symptomCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      final modelPerformance = <String, Map<String, dynamic>>{};
      for (final interaction in interactions) {
        final model = interaction['model_used']?.toString() ?? 'unknown';
        if (!modelPerformance.containsKey(model)) {
          modelPerformance[model] = {
            'total_requests': 0,
            'successful_requests': 0,
            'avg_response_time': 0,
          };
        }
        
        modelPerformance[model]!['total_requests'] = 
            (modelPerformance[model]!['total_requests'] as int) + 1;
        
        if (interaction['success'] == true) {
          modelPerformance[model]!['successful_requests'] = 
              (modelPerformance[model]!['successful_requests'] as int) + 1;
        }
      }

      return {
        'total_interactions': totalInteractions,
        'success_rate': successRate,
        'avg_response_time': avgResponseTime,
        'most_common_symptoms': mostCommonSymptoms.take(5).map((e) => e.key).toList(),
        'model_performance': modelPerformance,
      };
    } catch (e) {
      _logger.e('Error generating analytics summary: $e');
      return {
        'total_interactions': 0,
        'success_rate': 0.0,
        'avg_response_time': 0,
        'most_common_symptoms': [],
        'model_performance': {},
      };
    }
  }

  // Clear logs (for privacy/cleanup)
  Future<void> clearLogs() async {
    try {
      final logFile = File('logs/beforedoctor_analytics.log');
      if (await logFile.exists()) {
        await logFile.delete();
      }
      _logger.i('Logs cleared successfully');
    } catch (e) {
      _logger.e('Error clearing logs: $e');
    }
  }

  // Convenience methods for different log levels
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  // Log API calls with timing
  void logApiCall({
    required String endpoint,
    required String method,
    required int responseTime,
    required int statusCode,
    String? error,
  }) {
    final logData = {
      'endpoint': endpoint,
      'method': method,
      'response_time_ms': responseTime,
      'status_code': statusCode,
      'error': error,
    };

    if (error != null) {
      _logger.e('API_CALL_FAILED: $logData');
    } else {
      _logger.i('API_CALL_SUCCESS: $logData');
    }
  }

  // Log voice processing events
  void logVoiceProcessing({
    required String event,
    required String model,
    required double confidence,
    String? error,
  }) {
    final logData = {
      'event': event, // 'started', 'completed', 'failed'
      'model': model,
      'confidence': confidence,
      'error': error,
    };

    if (error != null) {
      _logger.e('VOICE_PROCESSING_ERROR: $logData');
    } else {
      _logger.i('VOICE_PROCESSING: $logData');
    }
  }

  // Log character interaction events
  void logCharacterInteraction({
    required String action,
    required String emotion,
    required int duration,
    String? error,
  }) {
    final logData = {
      'action': action, // 'speaking', 'listening', 'thinking'
      'emotion': emotion, // 'happy', 'concerned', 'neutral'
      'duration_ms': duration,
      'error': error,
    };

    if (error != null) {
      _logger.e('CHARACTER_INTERACTION_ERROR: $logData');
    } else {
      _logger.i('CHARACTER_INTERACTION: $logData');
    }
  }

  // Log AI orchestration interaction (from parent version)
  Future<void> logAIOrchestration({
    required List<String> symptoms,
    String? question,
    required Map<String, dynamic> cdcAssessment,
    required Map<String, dynamic> medicalResponse,
    required Map<String, dynamic> combinedResponse,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'ai_orchestration',
        'symptoms': symptoms,
        'question': question,
        'cdc_assessment': cdcAssessment,
        'medical_response': medicalResponse,
        'combined_response': combinedResponse,
      };
      
      _logger.i('AI_ORCHESTRATION: $logEntry');
    } catch (e) {
      _logger.e('Error logging AI orchestration: $e');
    }
  }
  
  // Log risk assessment (from parent version)
  Future<void> logRiskAssessment({
    required int childAge,
    required List<String> symptoms,
    required String riskLevel,
    required double riskScore,
    required String source,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'risk_assessment',
        'child_age': childAge,
        'symptoms': symptoms,
        'risk_level': riskLevel,
        'risk_score': riskScore,
        'source': source,
      };
      
      _logger.i('RISK_ASSESSMENT: $logEntry');
    } catch (e) {
      _logger.e('Error logging risk assessment: $e');
    }
  }
  
  // Log medical Q&A interaction (from parent version)
  Future<void> logMedicalQA({
    required String question,
    required String response,
    required String category,
    required Map<String, dynamic> context,
    required String source,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'medical_qa',
        'question': question,
        'response': response,
        'category': category,
        'context': context,
        'source': source,
      };
      
      _logger.i('MEDICAL_QA: $logEntry');
    } catch (e) {
      _logger.e('Error logging medical Q&A: $e');
    }
  }
} 