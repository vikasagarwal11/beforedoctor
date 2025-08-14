import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:rive/rive.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Manages Rive animations and (optionally) GLTF paths for the character.
class RiveAnimationManager {
  static final RiveAnimationManager _instance = RiveAnimationManager._internal();
  static RiveAnimationManager get instance => _instance;
  RiveAnimationManager._internal();

  final Logger _logger = Logger();

  // Controllers and artboards keyed by state name
  final Map<String, RiveAnimationController?> _controllers = {};
  final Map<String, Artboard> _artboards = {};

  String? _currentAnimation;
  bool _isInitialized = false;

  // Optional callbacks (no-ops if not set)
  Function(String)? _onAnimationStarted;
  Function(String)? _onAnimationCompleted;
  Function(String)? _onAnimationError;

  // Animation asset paths - Updated to use 3D character models instead of broken .riv files
  static const Map<String, String> _animationPaths = {
    // Obsolete GLTF paths - commented out for cleanup (not used by current app)
    // 'idle': 'assets/characters/mouse/scene.gltf',
    // 'listening': 'assets/characters/mouse/scene.gltf',
    // 'speaking': 'assets/characters/mouse/scene.gltf',
    // 'thinking': 'assets/characters/mouse/scene.gltf',
    // 'concerned': 'assets/characters/mouse/scene.gltf',
    // 'happy': 'assets/characters/mouse/scene.gltf',
    // 'explaining': 'assets/characters/mouse/scene.gltf',
    // 'lip_sync': 'assets/characters/mouse/scene.gltf',

    // 3D character models (handled by 3D viewer) - commented out for cleanup
    // 'mouse': 'assets/characters/mouse/scene.gltf',
    // 'hippo': 'assets/characters/hippo/scene.gltf',
    // 'jaguar': 'assets/characters/jaguar/scene.gltf',
    // 'rabbit': 'assets/characters/rabbit/scene.gltf',
  };

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _logger.i('🎭 Initializing Rive Animation Manager');

      // CRITICAL FIX for Rive 0.13.0: Initialize RiveFile before importing
      await RiveFile.initialize();

      // Test compatibility first
      await testRiveCompatibility();

      // Preload a minimal set that the UI expects immediately
      await _preloadCriticalAnimations();

      _isInitialized = true;
      _logger.i('🎭 Rive Animation Manager initialized');
    } catch (e) {
      _logger.e('❌ Rive Animation Manager init failed: $e');
      rethrow;
    }
  }

  void setOnAnimationStarted(Function(String) cb) => _onAnimationStarted = cb;
  void setOnAnimationCompleted(Function(String) cb) => _onAnimationCompleted = cb;
  void setOnAnimationError(Function(String) cb) => _onAnimationError = cb;

  Future<void> _preloadCriticalAnimations() async {
    const critical = ['idle', 'listening', 'speaking'];
    var loadedCount = 0;
    for (final name in critical) {
      await _loadAnimation(name);
      if (_artboards.containsKey(name)) {
        _logger.d('🎭 Preloaded: $name');
        loadedCount++;
      } else {
        _logger.w('⚠️ Failed to preload $name');
      }
    }
    if (loadedCount == 0) {
      _logger.w('! ! No Rive artboards loaded. Will rely on fallbacks.');
    } else {
      _logger.i('🎭 Successfully loaded $loadedCount Rive artboards');
    }
  }

  /// Loads a Rive animation (idempotent). Never throws up to callers.
  Future<void> _loadAnimation(String animationName) async {
    if (_artboards.containsKey(animationName)) return;

    final path = _animationPaths[animationName];
    if (path == null) {
      _logger.w('⚠️ No path for animation: $animationName');
      return;
    }
    if (_isGltf(path)) {
      // GLTF is handled by the 3D viewer, not here.
      _logger.d('ℹ️ Skipping GLTF in Rive manager: $path');
      return;
    }

    try {
      // CRITICAL FIX: use the exact ByteData slice returned by rootBundle.
      final data = await rootBundle.load(path);
      
      // Add size check for visibility (recommended by feedback)
      if (data.lengthInBytes < 128) {
        _logger.w('⚠️ $path seems too small (${data.lengthInBytes} bytes)');
      }
      
      final file = RiveFile.import(data); // throws if incompatible format
      final artboard = file.mainArtboard;

      // Try to attach a reasonable default controller so playAnimation works.
      // Prefer a state machine if available, else a simple animation named like the key.
      RiveAnimationController? controller;

      // Try common state machine names
      final candidates = ['State Machine 1', 'State Machine', 'Default'];
      StateMachineController? smController;
      for (final smName in candidates) {
        try {
          smController = StateMachineController.fromArtboard(artboard, smName);
          if (smController != null) break;
        } catch (_) {}
      }

      if (smController != null) {
        artboard.addController(smController);
        controller = smController;
      } else {
        // Fallback: simple animation. Try the same key name first, then the first animation available.
        SimpleAnimation? simple;
        try {
          simple = SimpleAnimation(animationName);
          artboard.addController(simple);
          controller = simple;
        } catch (_) {
          if (artboard.animations.isNotEmpty) {
            final firstAnimName = artboard.animations.first.name;
            simple = SimpleAnimation(firstAnimName);
            artboard.addController(simple);
            controller = simple;
            _logger.w("ℹ️ Using first animation '$firstAnimName' for '$animationName'");
          } else {
            _logger.w('⚠️ No animations or state machines inside $path');
          }
        }
      }

      _artboards[animationName] = artboard;
      _controllers[animationName] = controller;
      _logger.d('✅ Loaded artboard for $animationName');
    } catch (e) {
      if (e.toString().contains('format') || e.toString().contains('Rive')) {
        _logger.e('❌ Rive format error for $animationName: $e');
      } else {
        _logger.e('❌ Failed to load $animationName: $e');
      }
    }
  }

  bool _isGltf(String p) => p.toLowerCase().endsWith('.gltf') || p.toLowerCase().endsWith('.glb');

  Future<void> ensureLoaded(String animationName) => _loadAnimation(animationName);

  Artboard? getArtboard(String animationName) => _artboards[animationName];

  /// Plays an animation (best-effort). If controller missing, tries to attach one.
  Future<void> playAnimation(String animationName, {bool loop = false}) async {
    if (!_isInitialized) {
      _logger.w('⚠️ RiveAnimationManager not initialized yet');
      return;
    }

    await ensureLoaded(animationName);
    final artboard = _artboards[animationName];
    if (artboard == null) {
      _logger.w('⚠️ No artboard for $animationName');
      _onAnimationError?.call('Artboard missing for $animationName');
      return;
    }

    // Stop previous
    if (_currentAnimation != null && _currentAnimation != animationName) {
      await stopCurrentAnimation();
    }

    // Ensure we have an active controller
    RiveAnimationController? controller = _controllers[animationName];

    // If we didn’t manage to attach at load time, attach now
    if (controller == null) {
      // Try state machine first
      final candidates = ['State Machine 1', 'State Machine', 'Default'];
      for (final smName in candidates) {
        try {
          final sm = StateMachineController.fromArtboard(artboard, smName);
          if (sm != null) {
            artboard.addController(sm);
            controller = sm;
            break;
          }
        } catch (_) {}
      }
      // Else simple animation
      controller ??= SimpleAnimation(animationName, autoplay: true);
      artboard.addController(controller);
      _controllers[animationName] = controller;
    }

    controller.isActive = true; // loop is defined in the Rive file itself
    _currentAnimation = animationName;
    _onAnimationStarted?.call(animationName);
    _logger.d('▶️ Playing $animationName');
  }

  Future<void> playAnimationWithTransition(
    String animationName, {
    Duration transitionDuration = const Duration(milliseconds: 250),
  }) async {
    if (!_isInitialized) return;
    if (_currentAnimation == animationName) return;

    try {
      if (_currentAnimation != null) {
        final current = _controllers[_currentAnimation];
        if (current != null) {
          current.isActive = false;
          await Future.delayed(transitionDuration);
        }
      }
      await playAnimation(animationName);
    } catch (e) {
      _logger.e('❌ Transition to $animationName failed: $e');
      _onAnimationError?.call('$animationName: $e');
    }
  }

  Future<void> stopCurrentAnimation() async {
    if (_currentAnimation == null) return;
    final controller = _controllers[_currentAnimation];
    if (controller != null) controller.isActive = false;
    _currentAnimation = null;
    _logger.d('⏹️ Stopped current animation');
  }

  // Lip-sync helpers (viseme SMINumber or SMIBools)
  static const Map<String, int> _visemeIndex = {
    'mouth_closed': 0,
    'mouth_open_a': 1,
    'mouth_open_e': 2,
    'mouth_open_i': 3,
    'mouth_open_o': 4,
    'mouth_open_u': 5,
  };

  void applyMouthShape(String shape) {
    if (_currentAnimation == null) return;
    final controller = _controllers[_currentAnimation];
    if (controller is! StateMachineController) return;

    // Prefer a single viseme channel
    final vis = controller.findInput<double>('viseme') as SMINumber?;
    if (vis != null) {
      vis.value = (_visemeIndex[shape] ?? 0).toDouble();
      return;
    }

    // Else toggle bools
    const names = [
      'mouth_closed',
      'mouth_open_a',
      'mouth_open_e',
      'mouth_open_i',
      'mouth_open_o',
      'mouth_open_u',
    ];
    for (final n in names) {
      final b = controller.findInput<bool>(n) as SMIBool?;
      if (b != null) b.value = (n == shape);
    }
  }

  bool get isInitialized => _isInitialized;
  String? get currentAnimation => _currentAnimation;
  List<String> get availableAnimations => _animationPaths.keys.toList();

  // GLTF integration flags (just helpers)
  String get mouseModelPath => _animationPaths['mouse'] ?? '';
  bool get hasMouseModel => _animationPaths.containsKey('mouse');

  /// Test Rive file compatibility - helps diagnose format issues
  Future<void> testRiveCompatibility() async {
    _logger.i('🧪 Testing Rive file compatibility...');
    
    for (final entry in _animationPaths.entries) {
      final name = entry.key;
      final path = entry.value;
      
      if (_isGltf(path)) continue;
      
      try {
        final data = await rootBundle.load(path);
        _logger.i('📁 $name: ${data.lengthInBytes} bytes');
        
        if (data.lengthInBytes < 128) {
          _logger.w('⚠️ $name: File too small - may be corrupted');
          continue;
        }
        
        // Try to import - this will throw if format is incompatible
        final file = RiveFile.import(data);
        final artboard = file.mainArtboard;
        
        if (artboard == null) {
          _logger.w('⚠️ $name: No main artboard found');
        } else {
          _logger.i('✅ $name: Compatible format detected');
          _logger.i('   - Animations: ${artboard.animations.length}');
          _logger.i('   - Artboard size: ${artboard.width}x${artboard.height}');
        }
        
      } catch (e) {
        if (e.toString().contains('format') || e.toString().contains('Rive')) {
          _logger.e('❌ $name: INCOMPATIBLE FORMAT - needs re-export for Rive 2');
          _logger.e('   Error: $e');
        } else {
          _logger.e('❌ $name: Loading error: $e');
        }
      }
    }
  }

  void dispose() {
    for (final c in _controllers.values) {
      c?.dispose();
    }
    _controllers.clear();
    _artboards.clear();
    _currentAnimation = null;
    _onAnimationStarted = null;
    _onAnimationCompleted = null;
    _onAnimationError = null;
    _isInitialized = false;
    _logger.i('🧹 Rive Animation Manager disposed');
  }
}
