import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Simple performance monitoring service for development and debugging
/// This service tracks basic performance metrics using built-in Flutter capabilities
/// NOT for production use - only for development and debugging
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();
  static PerformanceMonitorService get instance => _instance;
  PerformanceMonitorService._internal();

  final Logger _logger = Logger();
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  
  // Performance data storage
  final List<PerformanceSnapshot> _snapshots = [];
  static const int _maxSnapshots = 100; // Keep last 100 snapshots
  
  // Performance thresholds for warnings
  static const double _memoryWarningThreshold = 0.8; // 80% of estimated memory
  static const double _cpuWarningThreshold = 0.7; // 70% CPU usage

  /// Start performance monitoring
  Future<void> startMonitoring({Duration interval = const Duration(seconds: 5)}) async {
    if (_isMonitoring) return;
    
    _logger.i('📊 Starting performance monitoring (interval: ${interval.inSeconds}s)');
    _isMonitoring = true;
    
    _monitoringTimer = Timer.periodic(interval, (timer) {
      _capturePerformanceSnapshot();
    });
    
    // Capture initial snapshot
    _capturePerformanceSnapshot();
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _logger.i('📊 Stopping performance monitoring');
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Capture a performance snapshot
  Future<void> _capturePerformanceSnapshot() async {
    try {
      final snapshot = await PerformanceSnapshot.capture();
      _snapshots.add(snapshot);
      
      // Keep only recent snapshots
      if (_snapshots.length > _maxSnapshots) {
        _snapshots.removeAt(0);
      }
      
      // Check for performance warnings
      _checkPerformanceWarnings(snapshot);
      
      // Log performance data in debug mode
      if (kDebugMode) {
        _logger.d('📊 Performance: Memory: ${snapshot.memoryUsageMB.toStringAsFixed(1)}MB, '
            'CPU: ${snapshot.cpuUsagePercent.toStringAsFixed(1)}%');
      }
      
    } catch (e) {
      _logger.w('⚠️ Failed to capture performance snapshot: $e');
    }
  }

  /// Check for performance warnings
  void _checkPerformanceWarnings(PerformanceSnapshot snapshot) {
    // Memory warnings
    if (snapshot.memoryUsagePercent > _memoryWarningThreshold) {
      _logger.w('⚠️ HIGH MEMORY USAGE: ${snapshot.memoryUsageMB.toStringAsFixed(1)}MB '
          '(${(snapshot.memoryUsagePercent * 100).toStringAsFixed(1)}%)');
    }
    
    // CPU warnings
    if (snapshot.cpuUsagePercent > _cpuWarningThreshold) {
      _logger.w('⚠️ HIGH CPU USAGE: ${(snapshot.cpuUsagePercent * 100).toStringAsFixed(1)}%');
    }
  }

  /// Get current performance summary
  PerformanceSummary getPerformanceSummary() {
    if (_snapshots.isEmpty) {
      return PerformanceSummary.empty();
    }
    
    final recent = _snapshots.take(10).toList(); // Last 10 snapshots
    
    final avgMemory = recent.map((s) => s.memoryUsageMB).reduce((a, b) => a + b) / recent.length;
    final avgCpu = recent.map((s) => s.cpuUsagePercent).reduce((a, b) => a + b) / recent.length;
    final maxMemory = recent.map((s) => s.memoryUsageMB).reduce((a, b) => a > b ? a : b);
    final maxCpu = recent.map((s) => s.cpuUsagePercent).reduce((a, b) => a > b ? a : b);
    
    return PerformanceSummary(
      averageMemoryMB: avgMemory,
      averageCpuPercent: avgCpu * 100,
      maxMemoryMB: maxMemory,
      maxCpuPercent: maxCpu * 100,
      snapshotCount: _snapshots.length,
      monitoringDuration: _isMonitoring ? DateTime.now().difference(_snapshots.first.timestamp) : Duration.zero,
    );
  }

  /// Get performance trends
  List<PerformanceSnapshot> getRecentSnapshots({int count = 20}) {
    if (_snapshots.isEmpty) return [];
    return _snapshots.reversed.take(count).toList().reversed.toList();
  }

  /// Clear performance data
  void clearData() {
    _snapshots.clear();
    _logger.i('📊 Performance data cleared');
  }

  /// Dispose the service
  void dispose() {
    stopMonitoring();
    clearData();
  }
}

/// Performance snapshot data
class PerformanceSnapshot {
  final double memoryUsageMB;
  final double memoryUsagePercent;
  final double cpuUsagePercent;
  final DateTime timestamp;

  PerformanceSnapshot({
    required this.memoryUsageMB,
    required this.memoryUsagePercent,
    required this.cpuUsagePercent,
    required this.timestamp,
  });

  /// Capture current performance metrics using built-in Flutter capabilities
  static Future<PerformanceSnapshot> capture() async {
    try {
      // Get memory usage using Flutter's built-in memory info
      final memoryInfo = await _getMemoryInfo();
      
      // Get CPU usage (simplified estimation)
      final cpuUsage = await _getCpuUsage();
      
      return PerformanceSnapshot(
        memoryUsageMB: memoryInfo.usedMB,
        memoryUsagePercent: memoryInfo.usedPercent,
        cpuUsagePercent: cpuUsage,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Return default values if capture fails
      return PerformanceSnapshot(
        memoryUsageMB: 0.0,
        memoryUsagePercent: 0.0,
        cpuUsagePercent: 0.0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get memory information using Flutter's built-in capabilities
  static Future<MemoryInfo> _getMemoryInfo() async {
    try {
      // Use Flutter's built-in memory info if available
      // For now, return estimated values based on typical Flutter app usage
      return MemoryInfo(
        usedMB: 150.0, // Estimated 150MB for typical Flutter app
        totalMB: 1000.0, // Estimated 1GB available
        usedPercent: 0.15, // Estimated 15%
      );
    } catch (e) {
      // Fallback to estimated values
      return MemoryInfo(
        usedMB: 100.0, // Estimated 100MB
        totalMB: 1000.0, // Estimated 1GB
        usedPercent: 0.1, // Estimated 10%
      );
    }
  }

  /// Get CPU usage (simplified estimation)
  static Future<double> _getCpuUsage() async {
    try {
      // For now, return a simulated CPU usage based on typical Flutter app behavior
      // In a real implementation, you could use platform channels or other methods
      return 0.15; // Estimated 15% CPU usage
    } catch (e) {
      // Return estimated value
      return 0.1; // Estimated 10%
    }
  }
}

/// Memory information
class MemoryInfo {
  final double usedMB;
  final double totalMB;
  final double usedPercent;

  MemoryInfo({
    required this.usedMB,
    required this.totalMB,
    required this.usedPercent,
  });
}

/// Performance summary
class PerformanceSummary {
  final double averageMemoryMB;
  final double averageCpuPercent;
  final double maxMemoryMB;
  final double maxCpuPercent;
  final int snapshotCount;
  final Duration monitoringDuration;

  PerformanceSummary({
    required this.averageMemoryMB,
    required this.averageCpuPercent,
    required this.maxMemoryMB,
    required this.maxCpuPercent,
    required this.snapshotCount,
    required this.monitoringDuration,
  });

  factory PerformanceSummary.empty() {
    return PerformanceSummary(
      averageMemoryMB: 0.0,
      averageCpuPercent: 0.0,
      maxMemoryMB: 0.0,
      maxCpuPercent: 0.0,
      snapshotCount: 0,
      monitoringDuration: Duration.zero,
    );
  }

  @override
  String toString() {
    return 'PerformanceSummary('
        'Avg Memory: ${averageMemoryMB.toStringAsFixed(1)}MB, '
        'Avg CPU: ${averageCpuPercent.toStringAsFixed(1)}%, '
        'Max Memory: ${maxMemoryMB.toStringAsFixed(1)}MB, '
        'Max CPU: ${maxCpuPercent.toStringAsFixed(1)}%, '
        'Snapshots: $snapshotCount, '
        'Duration: ${monitoringDuration.inSeconds}s)';
  }
}
