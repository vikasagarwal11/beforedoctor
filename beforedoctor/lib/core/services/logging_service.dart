import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

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
    dev.log('AI_INTERACTION: ${logData.toString()}');

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
      dev.log('Error writing to log file: $e');
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
              jsonStr.replaceAll('{', '').replaceAll('}', '').split(',')
                  .map((e) => e.trim().split(':'))
                  .where((e) => e.length == 2)
                  .map((e) => MapEntry(e[0].trim(), e[1].trim()))
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
      dev.log('Error generating analytics summary: $e');
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
    } catch (e) {
      dev.log('Error clearing logs: $e');
    }
  }
} 