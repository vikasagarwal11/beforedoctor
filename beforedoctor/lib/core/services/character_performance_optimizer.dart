import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:beforedoctor/core/services/character_animation_assets.dart';

/// Performance optimizer for character animations
/// Handles asset preloading, memory management, and performance monitoring
class CharacterPerformanceOptimizer {
  static CharacterPerformanceOptimizer? _instance;
  static CharacterPerformanceOptimizer get instance => _instance ??= CharacterPerformanceOptimizer._internal();

  CharacterPerformanceOptimizer._internal();

  // Asset management
  final Map<String, RiveFile> _loadedAssets = {};
  final Map<String, DateTime> _assetLastUsed = {};
  final Map<String, int> _assetUsageCount = {};
  
  // Performance tracking
  final List<PerformanceMetric> _performanceMetrics = [];
  DateTime _lastCleanup = DateTime.now();
  
  // Configuration
  static const int _maxLoadedAssets = 10;
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _assetTimeout = Duration(minutes: 15);
  
  // Memory management
  int _totalMemoryUsage = 0;
  static const int _maxMemoryUsage = 50 * 1024 * 1024; // 50MB
  
  // Callbacks
  Function(String)? onAssetLoaded;
  Function(String)? onAssetUnloaded;
  Function(PerformanceMetric)? onPerformanceUpdate;

  /// Initialize the performance optimizer
  Future<void> initialize() async {
    try {
      // Start performance monitoring
      _startPerformanceMonitoring();
      
      // Schedule periodic cleanup
      _scheduleCleanup();
      
      print('⚡ Character Performance Optimizer initialized');
    } catch (e) {
      print('❌ Error initializing Performance Optimizer: $e');
    }
  }

  /// Preload critical animations with priority
  Future<void> preloadCriticalAnimations() async {
    final criticalAnimations = CharacterAnimationAssets.getCriticalAnimations();
    
    for (final animationPath in criticalAnimations) {
      await _loadAsset(animationPath, priority: AssetPriority.critical);
    }
    
    print('⚡ Critical animations preloaded');
  }

  /// Preload animations based on usage patterns
  Future<void> preloadSmartAnimations() async {
    // Analyze usage patterns and preload accordingly
    final frequentlyUsed = _getFrequentlyUsedAssets();
    final predictedNeeded = _predictNextNeededAssets();
    
    final toPreload = {...frequentlyUsed, ...predictedNeeded};
    
    for (final animationPath in toPreload) {
      if (!_loadedAssets.containsKey(animationPath)) {
        await _loadAsset(animationPath, priority: AssetPriority.normal);
      }
    }
    
    print('⚡ Smart preloading completed');
  }

  /// Load an asset with priority management
  Future<RiveFile?> loadAsset(String animationPath, {AssetPriority priority = AssetPriority.normal}) async {
    // Check if already loaded
    if (_loadedAssets.containsKey(animationPath)) {
      _updateAssetUsage(animationPath);
      return _loadedAssets[animationPath];
    }
    
    // Check memory constraints
    if (_totalMemoryUsage > _maxMemoryUsage) {
      await _performMemoryCleanup();
    }
    
    // Load the asset
    return await _loadAsset(animationPath, priority: priority);
  }

  /// Internal asset loading with priority
  Future<RiveFile?> _loadAsset(String animationPath, {AssetPriority priority = AssetPriority.normal}) async {
    try {
      final startTime = DateTime.now();
      
      // Simulate asset loading (replace with actual implementation)
      final riveFile = await _simulateAssetLoad(animationPath);
      
      if (riveFile != null) {
        // Add to loaded assets
        _loadedAssets[animationPath] = riveFile;
        _assetLastUsed[animationPath] = DateTime.now();
        _assetUsageCount[animationPath] = 1;
        
        // Update memory usage (estimate)
        _totalMemoryUsage += _estimateAssetSize(animationPath);
        
        // Record performance metric
        final loadTime = DateTime.now().difference(startTime).inMilliseconds;
        _recordPerformanceMetric(PerformanceMetricType.assetLoad, loadTime, animationPath);
        
        onAssetLoaded?.call(animationPath);
        
        print('✅ Asset loaded: $animationPath (${loadTime}ms)');
      }
      
      return riveFile;
    } catch (e) {
      print('❌ Error loading asset $animationPath: $e');
      return null;
    }
  }

  /// Unload an asset to free memory
  Future<void> unloadAsset(String animationPath) async {
    if (_loadedAssets.containsKey(animationPath)) {
      final riveFile = _loadedAssets[animationPath]!;
      
      // Dispose Rive resources
      riveFile.dispose();
      
      // Remove from tracking
      _loadedAssets.remove(animationPath);
      _assetLastUsed.remove(animationPath);
      _assetUsageCount.remove(animationPath);
      
      // Update memory usage
      _totalMemoryUsage -= _estimateAssetSize(animationPath);
      
      onAssetUnloaded?.call(animationPath);
      
      print('🗑️ Asset unloaded: $animationPath');
    }
  }

  /// Get asset with usage tracking
  RiveFile? getAsset(String animationPath) {
    if (_loadedAssets.containsKey(animationPath)) {
      _updateAssetUsage(animationPath);
      return _loadedAssets[animationPath];
    }
    return null;
  }

  /// Update asset usage statistics
  void _updateAssetUsage(String animationPath) {
    _assetLastUsed[animationPath] = DateTime.now();
    _assetUsageCount[animationPath] = (_assetUsageCount[animationPath] ?? 0) + 1;
  }

  /// Get frequently used assets
  Set<String> _getFrequentlyUsedAssets() {
    final sortedAssets = _assetUsageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedAssets.take(5).map((e) => e.key).toSet();
  }

  /// Predict next needed assets based on patterns
  Set<String> _predictNextNeededAssets() {
    // Simple prediction: return animations that are commonly used together
    final predictions = <String>{};
    
    // Add related animations based on current context
    if (_loadedAssets.containsKey(CharacterAnimationAssets.idle)) {
      predictions.add(CharacterAnimationAssets.listening);
      predictions.add(CharacterAnimationAssets.speaking);
    }
    
    return predictions;
  }

  /// Perform memory cleanup
  Future<void> _performMemoryCleanup() async {
    print('🧹 Performing memory cleanup...');
    
    final assetsToUnload = <String>[];
    
    // Sort assets by last used time and usage count
    final sortedAssets = _assetLastUsed.entries.toList()
      ..sort((a, b) {
        final aUsage = _assetUsageCount[a.key] ?? 0;
        final bUsage = _assetUsageCount[b.key] ?? 0;
        
        // Prioritize by usage count first, then by last used time
        if (aUsage != bUsage) {
          return aUsage.compareTo(bUsage);
        }
        return a.value.compareTo(b.value);
      });
    
    // Unload least used assets until memory usage is acceptable
    for (final entry in sortedAssets) {
      if (_totalMemoryUsage <= _maxMemoryUsage * 0.7) break;
      
      final assetPath = entry.key;
      if (_isAssetCritical(assetPath)) continue; // Don't unload critical assets
      
      assetsToUnload.add(assetPath);
    }
    
    // Unload selected assets
    for (final assetPath in assetsToUnload) {
      await unloadAsset(assetPath);
    }
    
    print('🧹 Memory cleanup completed. Unloaded ${assetsToUnload.length} assets');
  }

  /// Check if asset is critical (should not be unloaded)
  bool _isAssetCritical(String assetPath) {
    return CharacterAnimationAssets.getCriticalAnimations().contains(assetPath);
  }

  /// Estimate asset size in bytes
  int _estimateAssetSize(String assetPath) {
    // Simple size estimation based on animation type
    if (assetPath.contains('idle')) return 50 * 1024; // 50KB
    if (assetPath.contains('speaking')) return 100 * 1024; // 100KB
    if (assetPath.contains('thinking')) return 75 * 1024; // 75KB
    return 60 * 1024; // Default 60KB
  }

  /// Simulate asset loading (replace with actual implementation)
  Future<RiveFile?> _simulateAssetLoad(String animationPath) async {
    // This is a placeholder - replace with actual asset loading logic
    await Future.delayed(Duration(milliseconds: 100)); // Simulate load time
    
    // For now, return null to indicate loading failure
    // In real implementation, this would load the actual Rive file
    return null;
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    // Monitor frame rate, memory usage, and asset performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePerformanceMetrics();
    });
  }

  /// Update performance metrics
  void _updatePerformanceMetrics() {
    final currentTime = DateTime.now();
    
    // Record memory usage
    final memoryMetric = PerformanceMetric(
      type: PerformanceMetricType.memoryUsage,
      value: _totalMemoryUsage,
      timestamp: currentTime,
      details: 'Total memory usage: ${(_totalMemoryUsage / 1024 / 1024).toStringAsFixed(2)}MB',
    );
    
    _performanceMetrics.add(memoryMetric);
    onPerformanceUpdate?.call(memoryMetric);
    
    // Keep only recent metrics
    if (_performanceMetrics.length > 100) {
      _performanceMetrics.removeRange(0, 20);
    }
  }

  /// Record performance metric
  void _recordPerformanceMetric(PerformanceMetricType type, int value, [String? details]) {
    final metric = PerformanceMetric(
      type: type,
      value: value,
      timestamp: DateTime.now(),
      details: details,
    );
    
    _performanceMetrics.add(metric);
    onPerformanceUpdate?.call(metric);
  }

  /// Schedule periodic cleanup
  void _scheduleCleanup() {
    Timer.periodic(_cleanupInterval, (timer) async {
      await _performPeriodicCleanup();
    });
  }

  /// Perform periodic cleanup
  Future<void> _performPeriodicCleanup() async {
    final currentTime = DateTime.now();
    
    // Clean up old assets
    final assetsToUnload = <String>[];
    
    for (final entry in _assetLastUsed.entries) {
      final assetPath = entry.key;
      final lastUsed = entry.value;
      
      if (currentTime.difference(lastUsed) > _assetTimeout) {
        if (!_isAssetCritical(assetPath)) {
          assetsToUnload.add(assetPath);
        }
      }
    }
    
    // Unload old assets
    for (final assetPath in assetsToUnload) {
      await unloadAsset(assetPath);
    }
    
    if (assetsToUnload.isNotEmpty) {
      print('🧹 Periodic cleanup: unloaded ${assetsToUnload.length} old assets');
    }
    
    _lastCleanup = currentTime;
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final recentMetrics = _performanceMetrics
        .where((m) => DateTime.now().difference(m.timestamp) < Duration(minutes: 5))
        .toList();
    
    return {
      'loaded_assets_count': _loadedAssets.length,
      'total_memory_usage_mb': (_totalMemoryUsage / 1024 / 1024).toStringAsFixed(2),
      'memory_usage_percentage': (_totalMemoryUsage / _maxMemoryUsage * 100).toStringAsFixed(1),
      'asset_usage_stats': Map.from(_assetUsageCount),
      'recent_performance_metrics': recentMetrics.length,
      'last_cleanup': _lastCleanup.toIso8601String(),
      'cleanup_interval_minutes': _cleanupInterval.inMinutes,
    };
  }

  /// Get loaded assets list
  List<String> getLoadedAssets() => _loadedAssets.keys.toList();
  
  /// Get asset usage statistics
  Map<String, int> getAssetUsageStats() => Map.from(_assetUsageCount);
  
  /// Get memory usage
  int get totalMemoryUsage => _totalMemoryUsage;
  
  /// Check if memory usage is high
  bool get isMemoryUsageHigh => _totalMemoryUsage > _maxMemoryUsage * 0.8;

  /// Dispose resources
  void dispose() {
    // Unload all assets
    for (final assetPath in _loadedAssets.keys.toList()) {
      unloadAsset(assetPath);
    }
    
    _loadedAssets.clear();
    _assetLastUsed.clear();
    _assetUsageCount.clear();
    _performanceMetrics.clear();
    
    print('⚡ Character Performance Optimizer disposed');
  }
}

/// Asset priority levels
enum AssetPriority {
  critical,    // Must be loaded and kept in memory
  high,        // High priority for preloading
  normal,      // Normal priority
  low,         // Low priority, can be unloaded first
}

/// Performance metric types
enum PerformanceMetricType {
  assetLoad,      // Asset loading time
  memoryUsage,    // Memory usage
  frameRate,      // Frame rate
  transitionTime, // State transition time
}

/// Performance metric data
class PerformanceMetric {
  final PerformanceMetricType type;
  final int value;
  final DateTime timestamp;
  final String? details;
  
  PerformanceMetric({
    required this.type,
    required this.value,
    required this.timestamp,
    this.details,
  });
  
  @override
  String toString() {
    return 'PerformanceMetric(type: ${type.name}, value: $value, timestamp: $timestamp, details: $details)';
  }
}
