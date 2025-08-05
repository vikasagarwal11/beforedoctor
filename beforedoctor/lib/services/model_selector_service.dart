import 'dart:math';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

enum AIModelType { openai, grok }

class ModelPerformance {
  int successCount = 0;
  int failureCount = 0;
  List<int> recentLatencies = [];
  DateTime lastUsed = DateTime.now();

  double get successRate => successCount + failureCount == 0
      ? 1.0
      : successCount / (successCount + failureCount);

  double get avgLatency => recentLatencies.isEmpty
      ? 9999
      : recentLatencies.reduce((a, b) => a + b) / recentLatencies.length;

  double get weightedScore {
    // Consider both success rate and latency, with recency bonus
    final baseScore = successRate / max(avgLatency, 1);
    final recencyBonus = DateTime.now().difference(lastUsed).inMinutes < 30 ? 0.1 : 0.0;
    return baseScore + recencyBonus;
  }

  Map<String, dynamic> toJson() => {
    'successCount': successCount,
    'failureCount': failureCount,
    'recentLatencies': recentLatencies,
    'lastUsed': lastUsed.toIso8601String(),
  };

  static ModelPerformance fromJson(Map<String, dynamic> json) {
    final performance = ModelPerformance();
    performance.successCount = json['successCount'] ?? 0;
    performance.failureCount = json['failureCount'] ?? 0;
    performance.recentLatencies = List<int>.from(json['recentLatencies'] ?? []);
    performance.lastUsed = DateTime.parse(json['lastUsed'] ?? DateTime.now().toIso8601String());
    return performance;
  }
}

class ModelSelectorService {
  static ModelSelectorService? _instance;
  static ModelSelectorService get instance => _instance ??= ModelSelectorService._internal();
  
  ModelSelectorService._internal();

  final Map<AIModelType, ModelPerformance> _stats = {
    AIModelType.openai: ModelPerformance(),
    AIModelType.grok: ModelPerformance(),
  };

  Database? _database;

  // Initialize database for persistence
  Future<void> initialize() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'model_performance.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE model_performance(
            model TEXT PRIMARY KEY,
            data TEXT
          )
        ''');
      },
      version: 1,
    );
    await _loadStats();
  }

  // Load stats from database
  Future<void> _loadStats() async {
    if (_database == null) return;
    
    final List<Map<String, dynamic>> maps = await _database!.query('model_performance');
    
    for (final map in maps) {
      final modelName = map['model'] as String;
      final data = json.decode(map['data'] as String);
      
      if (modelName == 'openai') {
        _stats[AIModelType.openai] = ModelPerformance.fromJson(data);
      } else if (modelName == 'grok') {
        _stats[AIModelType.grok] = ModelPerformance.fromJson(data);
      }
    }
  }

  // Save stats to database
  Future<void> _saveStats() async {
    if (_database == null) return;
    
    for (final entry in _stats.entries) {
      final modelName = entry.key.name;
      final data = json.encode(entry.value.toJson());
      
      await _database!.insert(
        'model_performance',
        {'model': modelName, 'data': data},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Record a model result
  Future<void> recordResult({
    required AIModelType model,
    required bool success,
    required int latencyMs,
  }) async {
    final stats = _stats[model]!;
    
    if (success) {
      stats.successCount += 1;
    } else {
      stats.failureCount += 1;
    }

    stats.recentLatencies.add(latencyMs);
    if (stats.recentLatencies.length > 5) {
      stats.recentLatencies.removeAt(0);
    }
    
    stats.lastUsed = DateTime.now();

    // Save to database
    await _saveStats();
  }

  // Get the best model based on performance
  AIModelType getBestModel() {
    final openaiStats = _stats[AIModelType.openai]!;
    final grokStats = _stats[AIModelType.grok]!;

    // Use weighted score that considers recency
    final openaiScore = openaiStats.weightedScore;
    final grokScore = grokStats.weightedScore;

    return openaiScore >= grokScore ? AIModelType.openai : AIModelType.grok;
  }

  // Get model performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final openaiStats = _stats[AIModelType.openai]!;
    final grokStats = _stats[AIModelType.grok]!;

    return {
      'openai': {
        'successRate': openaiStats.successRate,
        'avgLatency': openaiStats.avgLatency,
        'totalCalls': openaiStats.successCount + openaiStats.failureCount,
        'weightedScore': openaiStats.weightedScore,
        'lastUsed': openaiStats.lastUsed.toIso8601String(),
      },
      'grok': {
        'successRate': grokStats.successRate,
        'avgLatency': grokStats.avgLatency,
        'totalCalls': grokStats.successCount + grokStats.failureCount,
        'weightedScore': grokStats.weightedScore,
        'lastUsed': grokStats.lastUsed.toIso8601String(),
      },
      'recommendedModel': getBestModel().name,
    };
  }

  // Get model scores for UI display
  Map<String, double> getModelScores() {
    return {
      'openai': _stats[AIModelType.openai]!.weightedScore,
      'grok': _stats[AIModelType.grok]!.weightedScore,
    };
  }

  // Reset all stats
  Future<void> resetStats() async {
    _stats[AIModelType.openai] = ModelPerformance();
    _stats[AIModelType.grok] = ModelPerformance();
    await _saveStats();
  }

  // Get detailed performance for a specific model
  ModelPerformance getModelPerformance(AIModelType model) {
    return _stats[model]!;
  }

  // Check if a model is performing well recently
  bool isModelReliable(AIModelType model) {
    final stats = _stats[model]!;
    return stats.successRate >= 0.8 && stats.avgLatency < 5000; // 80% success, <5s latency
  }

  // Get recommendation with confidence
  Map<String, dynamic> getRecommendationWithConfidence() {
    final openaiStats = _stats[AIModelType.openai]!;
    final grokStats = _stats[AIModelType.grok]!;
    
    final openaiScore = openaiStats.weightedScore;
    final grokScore = grokStats.weightedScore;
    
    final recommended = openaiScore >= grokScore ? AIModelType.openai : AIModelType.grok;
    final scoreDifference = (openaiScore - grokScore).abs();
    
    String confidence;
    if (scoreDifference > 0.5) {
      confidence = 'high';
    } else if (scoreDifference > 0.2) {
      confidence = 'medium';
    } else {
      confidence = 'low';
    }

    return {
      'recommendedModel': recommended.name,
      'confidence': confidence,
      'scoreDifference': scoreDifference,
      'openaiScore': openaiScore,
      'grokScore': grokScore,
    };
  }

  // Simple getters for backward compatibility
  double get openaiScore => _stats[AIModelType.openai]!.successRate;
  double get grokScore => _stats[AIModelType.grok]!.successRate;

  // Dispose resources
  Future<void> dispose() async {
    await _database?.close();
  }
} 