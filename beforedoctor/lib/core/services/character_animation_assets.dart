// Filename: lib/core/services/character_animation_assets.dart
//
// Character Animation Assets Definition
// Defines all animation files, states, and specifications for Dr. Healthie
// - 7 character states with smooth transitions
// - Lip-sync animations for speech
// - Gesture-based interactions
// - Performance-optimized asset management

// No imports needed for this utility class

/// Animation asset definitions for Dr. Healthie character
class CharacterAnimationAssets {
  // Private constructor - singleton pattern
  CharacterAnimationAssets._();
  
  // Base path for animation assets
  static const String _basePath = 'assets/animations';
  
  // ===== CHARACTER STATE ANIMATIONS =====
  
  /// Idle state - gentle breathing, friendly presence
  static const String idle = '$_basePath/doctor_idle.riv';
  
  /// Listening state - attentive pose, nodding
  static const String listening = '$_basePath/doctor_listening.riv';
  
  /// Speaking state - lip-sync, hand gestures
  static const String speaking = '$_basePath/doctor_speaking.riv';
  
  /// Thinking state - hand on chin, thoughtful
  static const String thinking = '$_basePath/doctor_thinking.riv';
  
  /// Concerned state - worried expression, medical posture
  static const String concerned = '$_basePath/doctor_concerned.riv';
  
  /// Happy state - warm smile, encouraging gestures
  static const String happy = '$_basePath/doctor_happy.riv';
  
  /// Explaining state - pointing, medical diagrams
  static const String explaining = '$_basePath/doctor_explaining.riv';
  
  // ===== SPECIALIZED ANIMATIONS =====
  
  /// Lip-sync animation for speech
  static const String lipSync = '$_basePath/doctor_lip_sync.riv';
  
  /// Medical examination gestures
  static const String examining = '$_basePath/doctor_examining.riv';
  
  /// Calming gestures for anxious children
  static const String calming = '$_basePath/doctor_calming.riv';
  
  /// Celebration for good news
  static const String celebration = '$_basePath/doctor_celebration.riv';
  
  // ===== ANIMATION SPECIFICATIONS =====
  
  /// Default animation duration for state transitions
  static const Duration defaultTransitionDuration = Duration(milliseconds: 500);
  
  /// Lip-sync animation speed (words per minute)
  static const double defaultSpeechRate = 150.0;
  
  /// Character scale for different screen sizes
  static const double defaultCharacterScale = 1.0;
  
  // ===== STATE TRANSITION MAPPINGS =====
  
  /// Maps character states to their animation files
  static const Map<String, String> stateAnimations = {
    'idle': idle,
    'listening': listening,
    'speaking': speaking,
    'thinking': thinking,
    'concerned': concerned,
    'happy': happy,
    'explaining': explaining,
  };
  
  /// Maps emotional tones to animation states
  static const Map<String, String> toneAnimations = {
    'neutral': idle,
    'friendly': happy,
    'concerned': concerned,
    'encouraging': happy,
    'professional': explaining,
    'playful': happy,
  };
  
  /// Maps medical urgency levels to character states
  static const Map<String, String> urgencyAnimations = {
    'low': happy,
    'medium': explaining,
    'high': concerned,
    'urgent': concerned,
    'emergency': concerned,
  };
  
  // ===== PERFORMANCE OPTIMIZATION =====
  
  /// Preload priority for animations (higher = load first)
  static const Map<String, int> preloadPriority = {
    idle: 1,           // Always loaded
    listening: 2,      // High priority
    speaking: 2,       // High priority
    thinking: 3,       // Medium priority
    concerned: 3,      // Medium priority
    happy: 4,          // Lower priority
    explaining: 4,     // Lower priority
  };
  
  /// Animation file sizes (for memory management)
  static const Map<String, int> estimatedFileSizes = {
    idle: 50,          // KB
    listening: 75,     // KB
    speaking: 100,     // KB
    thinking: 60,      // KB
    concerned: 80,     // KB
    happy: 70,         // KB
    explaining: 90,    // KB
  };
  
  // ===== VALIDATION METHODS =====
  
  /// Check if all required animation files exist
  static List<String> getRequiredAssets() {
    return stateAnimations.values.toList();
  }
  
  /// Get total estimated size of all animations
  static int getTotalEstimatedSize() {
    return estimatedFileSizes.values.reduce((a, b) => a + b);
  }
  
  /// Validate animation path exists
  static bool isValidAnimationPath(String path) {
    return stateAnimations.values.contains(path) || 
           path == lipSync || 
           path == examining || 
           path == calming || 
           path == celebration;
  }
  
  /// Get animation for specific state
  static String? getAnimationForState(String state) {
    return stateAnimations[state.toLowerCase()];
  }
  
  /// Get animation for emotional tone
  static String? getAnimationForTone(String tone) {
    return toneAnimations[tone.toLowerCase()];
  }
  
  /// Get animation for medical urgency
  static String? getAnimationForUrgency(String urgency) {
    return urgencyAnimations[urgency.toLowerCase()];
  }
  
  // ===== ASSET PRELOADING =====
  
  /// Get preload order for optimal performance
  static List<String> getPreloadOrder() {
    final sorted = preloadPriority.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sorted.map((e) => e.key).toList();
  }
  
  /// Get critical animations that must be loaded first
  static List<String> getCriticalAnimations() {
    return preloadPriority.entries
        .where((e) => e.value <= 2)
        .map((e) => e.key)
        .toList();
  }
  
  /// Get non-critical animations for lazy loading
  static List<String> getNonCriticalAnimations() {
    return preloadPriority.entries
        .where((e) => e.value > 2)
        .map((e) => e.key)
        .toList();
  }
}
