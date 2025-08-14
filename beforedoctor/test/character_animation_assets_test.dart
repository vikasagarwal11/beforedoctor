// Filename: test/character_animation_assets_test.dart
//
// Test file for CharacterAnimationAssets class
// Verifies all methods work correctly and return expected values

import 'package:flutter_test/flutter_test.dart';
import 'package:beforedoctor/core/services/character_animation_assets.dart';

void main() {
  group('CharacterAnimationAssets', () {
    test('should return correct base path', () {
      expect(CharacterAnimationAssets.idle, contains('assets/animations'));
      expect(CharacterAnimationAssets.listening, contains('assets/animations'));
      expect(CharacterAnimationAssets.speaking, contains('assets/animations'));
    });

    test('should return all required assets', () {
      final assets = CharacterAnimationAssets.getRequiredAssets();
      expect(assets.length, 7); // 7 character states
      expect(assets, contains(CharacterAnimationAssets.idle));
      expect(assets, contains(CharacterAnimationAssets.listening));
      expect(assets, contains(CharacterAnimationAssets.speaking));
      expect(assets, contains(CharacterAnimationAssets.thinking));
      expect(assets, contains(CharacterAnimationAssets.concerned));
      expect(assets, contains(CharacterAnimationAssets.happy));
      expect(assets, contains(CharacterAnimationAssets.explaining));
    });

    test('should validate animation paths correctly', () {
      expect(CharacterAnimationAssets.isValidAnimationPath(CharacterAnimationAssets.idle), true);
      expect(CharacterAnimationAssets.isValidAnimationPath(CharacterAnimationAssets.lipSync), true);
      expect(CharacterAnimationAssets.isValidAnimationPath('invalid_path.riv'), false);
    });

    test('should get animation for state', () {
      expect(CharacterAnimationAssets.getAnimationForState('idle'), CharacterAnimationAssets.idle);
      expect(CharacterAnimationAssets.getAnimationForState('IDLE'), CharacterAnimationAssets.idle);
      expect(CharacterAnimationAssets.getAnimationForState('invalid'), null);
    });

    test('should get animation for emotional tone', () {
      expect(CharacterAnimationAssets.getAnimationForTone('neutral'), CharacterAnimationAssets.idle);
      expect(CharacterAnimationAssets.getAnimationForTone('friendly'), CharacterAnimationAssets.happy);
      expect(CharacterAnimationAssets.getAnimationForTone('concerned'), CharacterAnimationAssets.concerned);
    });

    test('should get animation for medical urgency', () {
      expect(CharacterAnimationAssets.getAnimationForUrgency('low'), CharacterAnimationAssets.happy);
      expect(CharacterAnimationAssets.getAnimationForUrgency('high'), CharacterAnimationAssets.concerned);
      expect(CharacterAnimationAssets.getAnimationForUrgency('emergency'), CharacterAnimationAssets.concerned);
    });

    test('should return correct preload order', () {
      final preloadOrder = CharacterAnimationAssets.getPreloadOrder();
      expect(preloadOrder.first, CharacterAnimationAssets.idle); // Priority 1
      expect(preloadOrder.length, 7);
    });

    test('should return critical animations', () {
      final critical = CharacterAnimationAssets.getCriticalAnimations();
      expect(critical, contains(CharacterAnimationAssets.idle));
      expect(critical, contains(CharacterAnimationAssets.listening));
      expect(critical, contains(CharacterAnimationAssets.speaking));
      expect(critical.length, 3); // Priority 1-2
    });

    test('should return non-critical animations', () {
      final nonCritical = CharacterAnimationAssets.getNonCriticalAnimations();
      expect(nonCritical, contains(CharacterAnimationAssets.thinking));
      expect(nonCritical, contains(CharacterAnimationAssets.concerned));
      expect(nonCritical, contains(CharacterAnimationAssets.happy));
      expect(nonCritical, contains(CharacterAnimationAssets.explaining));
      expect(nonCritical.length, 4); // Priority 3-4
    });

    test('should calculate total estimated size', () {
      final totalSize = CharacterAnimationAssets.getTotalEstimatedSize();
      expect(totalSize, 525); // 50+75+100+60+80+70+90 = 525 KB
    });

    test('should have correct animation specifications', () {
      expect(CharacterAnimationAssets.defaultTransitionDuration, const Duration(milliseconds: 500));
      expect(CharacterAnimationAssets.defaultSpeechRate, 150.0);
      expect(CharacterAnimationAssets.defaultCharacterScale, 1.0);
    });
  });
}
