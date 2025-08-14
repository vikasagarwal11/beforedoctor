import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:beforedoctor/core/services/character_animation_assets.dart';

/// Advanced animation controller for Dr. Healthie character
/// Manages Rive animations, state transitions, and performance optimization
class CharacterAnimationController {
  static CharacterAnimationController? _instance;
  static CharacterAnimationController get instance => _instance ??= CharacterAnimationController._internal();

  CharacterAnimationController._internal();

  // Rive controllers
  RiveAnimationController? _stateController;
  RiveAnimationController? _lipSyncController;
  RiveAnimationController? _gestureController;
  
  // Artboard and state machine
  Artboard? _artboard;
  StateMachineController? _stateMachine;
  
  // Animation state tracking
  String _currentAnimation = '';
  bool _isTransitioning = false;
  bool _isLipSyncing = false;
  
  // Performance optimization
  final Map<String, RiveFile> _preloadedAnimations = {};
  final Map<String, bool> _animationCache = {};
  
  // Callbacks
  Function(String)? onAnimationChanged;
  Function(double)? onAnimationProgress;
  Function()? onAnimationComplete;
  Function(String)? onStateTransition;

  /// Initialize the animation controller
  Future<void> initialize() async {
    try {
      // Preload critical animations
      await _preloadCriticalAnimations();
      
      // Initialize state machine if available
      await _initializeStateMachine();
      
      print('🎭 Animation Controller initialized successfully');
    } catch (e) {
      print('❌ Error initializing Animation Controller: $e');
    }
  }

  /// Preload critical animations for performance
  Future<void> _preloadCriticalAnimations() async {
    final criticalAnimations = CharacterAnimationAssets.getCriticalAnimations();
    
    for (final animationPath in criticalAnimations) {
      try {
        final bytes = await _loadAnimationBytes(animationPath);
        if (bytes != null) {
          _preloadedAnimations[animationPath] = RiveFile.import(bytes);
          _animationCache[animationPath] = true;
          print('✅ Preloaded: $animationPath');
        }
      } catch (e) {
        print('⚠️ Failed to preload $animationPath: $e');
      }
    }
  }

  /// Initialize Rive state machine if available
  Future<void> _initializeStateMachine() async {
    try {
      final idlePath = CharacterAnimationAssets.idle;
      final bytes = await _loadAnimationBytes(idlePath);
      
      if (bytes != null) {
        _artboard = RiveFile.import(bytes).mainArtboard;
        
        // Try to get state machine
        final stateMachines = _artboard!.stateMachines;
        if (stateMachines.isNotEmpty) {
          _stateMachine = StateMachineController.fromStateMachine(
            _artboard!,
            stateMachines.first,
          );
          _artboard!.addController(_stateMachine!);
          print('✅ State machine initialized');
        }
        
        // Set initial state
        _currentAnimation = idlePath;
        _updateAnimationDisplay();
      }
    } catch (e) {
      print('⚠️ State machine initialization failed: $e');
    }
  }

  /// Load animation bytes from asset path
  Future<Uint8List?> _loadAnimationBytes(String path) async {
    try {
      // This would typically use rootBundle.load() in a real implementation
      // For now, we'll return null to indicate the animation needs to be loaded
      return null;
    } catch (e) {
      print('❌ Error loading animation bytes: $e');
      return null;
    }
  }

  /// Change character state with smooth transition
  Future<void> changeState(String state, {Duration? transitionDuration}) async {
    if (_isTransitioning) return;
    
    final animationPath = CharacterAnimationAssets.getAnimationForState(state);
    if (animationPath == null) {
      print('⚠️ No animation found for state: $state');
      return;
    }

    _isTransitioning = true;
    onStateTransition?.call(state);

    try {
      // Stop current animation
      await _stopCurrentAnimation();
      
      // Load and play new animation
      await _playAnimation(animationPath, transitionDuration);
      
      _currentAnimation = animationPath;
      onAnimationChanged?.call(state);
      
      print('🎭 State changed to: $state');
    } catch (e) {
      print('❌ Error changing state: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  /// Play animation with optional transition duration
  Future<void> _playAnimation(String animationPath, Duration? transitionDuration) async {
    try {
      // Check if animation is preloaded
      RiveFile? riveFile = _preloadedAnimations[animationPath];
      
      if (riveFile == null) {
        // Load animation on demand
        final bytes = await _loadAnimationBytes(animationPath);
        if (bytes != null) {
          riveFile = RiveFile.import(bytes);
          _preloadedAnimations[animationPath] = riveFile;
        }
      }
      
      if (riveFile != null) {
        final artboard = riveFile.mainArtboard;
        final animation = artboard.animations.first;
        
        // Create and start animation controller
        _stateController?.dispose();
        _stateController = AnimationController(animation);
        _stateController!.isActive = true;
        
        // Add controller to artboard
        artboard.addController(_stateController!);
        
        // Set up animation completion callback
        _stateController!.isActiveChanged.addListener(() {
          if (!_stateController!.isActive) {
            onAnimationComplete?.call();
          }
        });
        
        // Set transition duration if specified
        if (transitionDuration != null) {
          _stateController!.duration = transitionDuration.inMilliseconds;
        }
        
        _updateAnimationDisplay();
      }
    } catch (e) {
      print('❌ Error playing animation: $e');
    }
  }

  /// Stop current animation
  Future<void> _stopCurrentAnimation() async {
    if (_stateController != null) {
      _stateController!.isActive = false;
      _stateController!.dispose();
      _stateController = null;
    }
  }

  /// Start lip sync animation
  Future<void> startLipSync() async {
    if (_isLipSyncing) return;
    
    _isLipSyncing = true;
    
    try {
      final lipSyncPath = CharacterAnimationAssets.lipSync;
      if (lipSyncPath != null) {
        await _playAnimation(lipSyncPath, null);
        print('🎭 Lip sync started');
      }
    } catch (e) {
      print('❌ Error starting lip sync: $e');
    }
  }

  /// Stop lip sync animation
  Future<void> stopLipSync() async {
    if (!_isLipSyncing) return;
    
    _isLipSyncing = false;
    
    try {
      await _stopCurrentAnimation();
      // Return to previous state
      await changeState('idle');
      print('🎭 Lip sync stopped');
    } catch (e) {
      print('❌ Error stopping lip sync: $e');
    }
  }

  /// Play gesture animation
  Future<void> playGesture(String gestureType) async {
    try {
      final gesturePath = CharacterAnimationAssets.getAnimationForGesture(gestureType);
      if (gesturePath != null) {
        await _playAnimation(gesturePath, Duration(milliseconds: 1000));
        print('🎭 Gesture played: $gestureType');
      }
    } catch (e) {
      print('❌ Error playing gesture: $e');
    }
  }

  /// Update animation display (for debugging/monitoring)
  void _updateAnimationDisplay() {
    // This could update UI elements showing current animation state
    print('🎭 Current animation: $_currentAnimation');
  }

  /// Get current animation state
  String get currentAnimation => _currentAnimation;
  
  /// Check if transitioning
  bool get isTransitioning => _isTransitioning;
  
  /// Check if lip syncing
  bool get isLipSyncing => _isLipSyncing;

  /// Preload additional animations
  Future<void> preloadAnimations(List<String> animationPaths) async {
    for (final path in animationPaths) {
      if (!_animationCache.containsKey(path)) {
        try {
          final bytes = await _loadAnimationBytes(path);
          if (bytes != null) {
            _preloadedAnimations[path] = RiveFile.import(bytes);
            _animationCache[path] = true;
            print('✅ Preloaded: $path');
          }
        } catch (e) {
          print('⚠️ Failed to preload $path: $e');
        }
      }
    }
  }

  /// Get animation performance stats
  Map<String, dynamic> getPerformanceStats() {
    return {
      'preloaded_count': _preloadedAnimations.length,
      'cache_hit_rate': _animationCache.length > 0 ? 
          _preloadedAnimations.length / _animationCache.length : 0.0,
      'current_animation': _currentAnimation,
      'is_transitioning': _isTransitioning,
      'is_lip_syncing': _isLipSyncing,
    };
  }

  /// Dispose resources
  void dispose() {
    _stateController?.dispose();
    _lipSyncController?.dispose();
    _gestureController?.dispose();
    _stateMachine?.dispose();
    
    _preloadedAnimations.clear();
    _animationCache.clear();
    
    print('🎭 Animation Controller disposed');
  }
}
