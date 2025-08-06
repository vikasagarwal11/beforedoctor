import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UsageLoggerService {
  static Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'beforedoctor_logs.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            symptom TEXT,
            prompt_used TEXT,
            model_used TEXT,
            ai_response TEXT,
            latency_ms INTEGER,
            success INTEGER,
            score REAL,
            interaction_type TEXT,
            child_age TEXT,
            child_gender TEXT,
            voice_confidence REAL,
            error_message TEXT,
            uploaded INTEGER DEFAULT 0
          )
        ''');
      },
      version: 1,
    );
  }

  Future<void> logInteraction({
    required String symptom,
    required String promptUsed,
    required String modelUsed,
    required String aiResponse,
    required int latencyMs,
    required bool success,
    required double score,
    String? interactionType,
    String? childAge,
    String? childGender,
    double? voiceConfidence,
    String? errorMessage,
  }) async {
    if (_db == null) await init();

    await _db!.insert('logs', {
      'timestamp': DateTime.now().toIso8601String(),
      'symptom': symptom,
      'prompt_used': promptUsed,
      'model_used': modelUsed,
      'ai_response': aiResponse,
      'latency_ms': latencyMs,
      'success': success ? 1 : 0,
      'score': score,
      'interaction_type': interactionType ?? 'unknown',
      'child_age': childAge ?? '',
      'child_gender': childGender ?? '',
      'voice_confidence': voiceConfidence ?? 0.0,
      'error_message': errorMessage ?? '',
    });
  }

  Future<List<Map<String, dynamic>>> getAllLogs() async {
    if (_db == null) await init();
    return await _db!.query('logs', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getLogsByDateRange(DateTime start, DateTime end) async {
    if (_db == null) await init();
    return await _db!.query(
      'logs',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getLogsByModel(String model) async {
    if (_db == null) await init();
    return await _db!.query(
      'logs',
      where: 'model_used = ?',
      whereArgs: [model],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getSuccessfulLogs() async {
    if (_db == null) await init();
    return await _db!.query(
      'logs',
      where: 'success = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getFailedLogs() async {
    if (_db == null) await init();
    return await _db!.query(
      'logs',
      where: 'success = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
  }

  // Get logs that haven't been uploaded yet
  Future<List<Map<String, dynamic>>> getUnuploadedLogs() async {
    if (_db == null) await init();
    return await _db!.query(
      'logs',
      where: 'uploaded = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
  }

  // Mark logs as uploaded
  Future<void> markLogsAsUploaded(List<int> logIds) async {
    if (_db == null) await init();
    for (final id in logIds) {
      await _db!.update(
        'logs',
        {'uploaded': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Mark all logs as uploaded
  Future<void> markAllLogsAsUploaded() async {
    if (_db == null) await init();
    await _db!.update(
      'logs',
      {'uploaded': 1},
      where: 'uploaded = ?',
      whereArgs: [0],
    );
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    if (_db == null) await init();
    
    final allLogs = await getAllLogs();
    final successfulLogs = await getSuccessfulLogs();
    final failedLogs = await getFailedLogs();
    
    // Calculate average latency
    final totalLatency = allLogs.fold<int>(0, (sum, log) => sum + (log['latency_ms'] as int? ?? 0));
    final avgLatency = allLogs.isNotEmpty ? totalLatency / allLogs.length : 0;
    
    // Calculate average score
    final totalScore = allLogs.fold<double>(0.0, (sum, log) => sum + (log['score'] as double? ?? 0.0));
    final avgScore = allLogs.isNotEmpty ? totalScore / allLogs.length : 0.0;
    
    // Model usage statistics
    final modelStats = <String, int>{};
    for (final log in allLogs) {
      final model = log['model_used'] as String? ?? 'unknown';
      modelStats[model] = (modelStats[model] ?? 0) + 1;
    }
    
    return {
      'total_interactions': allLogs.length,
      'successful_interactions': successfulLogs.length,
      'failed_interactions': failedLogs.length,
      'success_rate': allLogs.isNotEmpty ? (successfulLogs.length / allLogs.length) * 100 : 0.0,
      'average_latency_ms': avgLatency,
      'average_score': avgScore,
      'model_usage': modelStats,
      'last_interaction': allLogs.isNotEmpty ? allLogs.first['timestamp'] : null,
    };
  }

  Future<void> clearLogs() async {
    if (_db == null) await init();
    await _db!.delete('logs');
  }

  Future<void> deleteLog(int id) async {
    if (_db == null) await init();
    await _db!.delete('logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
} 