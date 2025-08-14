import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:beforedoctor/core/services/character_interaction_engine.dart';
import 'package:beforedoctor/core/services/rive_animation_manager.dart';
import 'package:beforedoctor/core/services/lip_sync_service.dart';
import 'package:beforedoctor/core/providers/character_state_provider.dart';
import 'package:beforedoctor/features/character/presentation/screens/enhanced_doctor_character_screen.dart';

// Generate mocks for integration testing
@GenerateMocks([
  CharacterInteractionEngine,
  RiveAnimationManager,
  LipSyncService,
])
import 'animated_character_integration_test.mocks.dart';

void main() {
  group('Animated Character System Integration Tests', () {
    late ProviderContainer container;
    late MockCharacterInteractionEngine mockCharacterEngine;
    late MockRiveAnimationManager mockAnimationManager;
    late MockLipSyncService mockLipSyncService;

    setUp(() {
      // Create mocks
      mockCharacterEngine = MockCharacterInteractionEngine();
      mockAnimationManager = MockRiveAnimationManager();
      mockLipSyncService = MockLipSyncService();

      // Set up default mock behaviors
      when(mockCharacterEngine.initialize()).thenAnswer((_) async {});
      when(mockAnimationManager.initialize()).thenAnswer((_) async {});
      when(mockLipSyncService.initialize()).thenAnswer((_) async {});
      when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
      when(mockAnimationManager.playAnimation(any)).thenAnswer((_) async {});
      when(mockLipSyncService.speakWithLipSync(any)).thenAnswer((_) async {});
      when(mockLipSyncService.stopSpeaking()).thenAnswer((_) async {});
      when(mockCharacterEngine.changeEmotionalTone(any)).thenAnswer((_) async {});

      // Create provider container with overrides
      container = ProviderContainer(
        overrides: [
          characterEngineProvider.overrideWithValue(mockCharacterEngine),
          riveAnimationManagerProvider.overrideWithValue(mockAnimationManager),
          lipSyncServiceProvider.overrideWithValue(mockLipSyncService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Complete System Initialization', () {
      test('should initialize all services and providers correctly', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);

        // Act
        await characterStateNotifier.initialize();

        // Assert
        final state = container.read(characterStateProvider);
        expect(state.isInitialized, isTrue);
        expect(state.status, CharacterStatus.ready);
        expect(state.currentState, 'idle');
        expect(state.currentEmotionalTone, 'neutral');

        // Verify all services were initialized
        verify(mockCharacterEngine.initialize()).called(1);
        verify(mockAnimationManager.initialize()).called(1);
        verify(mockLipSyncService.initialize()).called(1);
      });

      test('should handle partial service failures gracefully', () async {
        // Arrange
        when(mockAnimationManager.initialize()).thenThrow(Exception('Animation service unavailable'));
        final characterStateNotifier = container.read(characterStateProvider.notifier);

        // Act
        await characterStateNotifier.initialize();

        // Assert
        final state = container.read(characterStateProvider);
        expect(state.isInitialized, isFalse);
        expect(state.status, CharacterStatus.error);
        expect(state.errorMessage, contains('Animation service unavailable'));

        // Verify successful services were still initialized
        verify(mockCharacterEngine.initialize()).called(1);
        verify(mockLipSyncService.initialize()).called(1);
      });
    });

    group('Character State Flow Integration', () {
      test('should handle complete conversation flow with state transitions', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        const conversationMessage = 'Hello! I\'m Dr. Care. How can I help you today?';

        // Act - Simulate complete conversation flow
        // 1. Start listening
        await characterStateNotifier.startListening();
        
        // 2. Start speaking
        await characterStateNotifier.startSpeaking(conversationMessage);
        
        // 3. Stop speaking
        await characterStateNotifier.stopSpeaking();

        // Assert
        final finalState = container.read(characterStateProvider);
        expect(finalState.currentState, 'idle');
        expect(finalState.isSpeaking, isFalse);
        expect(finalState.isListening, isFalse);
        expect(finalState.status, CharacterStatus.ready);
        expect(finalState.conversationHistory, contains(conversationMessage));

        // Verify state transitions
        verify(mockCharacterEngine.changeState('listening')).called(1);
        verify(mockCharacterEngine.changeState('speaking')).called(1);
        verify(mockCharacterEngine.changeState('idle')).called(1);

        // Verify animations
        verify(mockAnimationManager.playAnimation('listening')).called(1);
        verify(mockAnimationManager.playAnimation('speaking')).called(1);
        verify(mockAnimationManager.playAnimation('idle')).called(1);

        // Verify lip-sync
        verify(mockLipSyncService.speakWithLipSync(conversationMessage)).called(1);
        verify(mockLipSyncService.stopSpeaking()).called(1);
      });

      test('should maintain conversation history across multiple interactions', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        const message1 = 'Hello there!';
        const message2 = 'How are you feeling?';
        const message3 = 'I\'m here to help.';

        // Act - Multiple conversation turns
        await characterStateNotifier.startSpeaking(message1);
        await characterStateNotifier.stopSpeaking();
        
        await characterStateNotifier.startSpeaking(message2);
        await characterStateNotifier.stopSpeaking();
        
        await characterStateNotifier.startSpeaking(message3);
        await characterStateNotifier.stopSpeaking();

        // Assert
        final finalState = container.read(characterStateProvider);
        expect(finalState.conversationHistory, hasLength(3));
        expect(finalState.conversationHistory, contains(message1));
        expect(finalState.conversationHistory, contains(message2));
        expect(finalState.conversationHistory, contains(message3));
        expect(finalState.lastMessageTime, isNotNull);
      });
    });

    group('Emotional Tone Integration', () {
      test('should change emotional tone and maintain state consistency', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Change emotional tone
        await characterStateNotifier.changeEmotionalTone('encouraging');
        await characterStateNotifier.changeEmotionalTone('professional');
        await characterStateNotifier.changeEmotionalTone('friendly');

        // Assert
        final finalState = container.read(characterStateProvider);
        expect(finalState.currentEmotionalTone, 'friendly');
        expect(finalState.lastToneChange, isNotNull);

        // Verify emotional tone changes
        verify(mockCharacterEngine.changeEmotionalTone('encouraging')).called(1);
        verify(mockCharacterEngine.changeEmotionalTone('professional')).called(1);
        verify(mockCharacterEngine.changeEmotionalTone('friendly')).called(1);
      });

      test('should combine emotional tone with character states', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Change both state and emotional tone
        await characterStateNotifier.changeState('speaking');
        await characterStateNotifier.changeEmotionalTone('encouraging');

        // Assert
        final finalState = container.read(characterStateProvider);
        expect(finalState.currentState, 'speaking');
        expect(finalState.currentEmotionalTone, 'encouraging');

        // Verify both changes were applied
        verify(mockCharacterEngine.changeState('speaking')).called(1);
        verify(mockCharacterEngine.changeEmotionalTone('encouraging')).called(1);
        verify(mockAnimationManager.playAnimation('speaking')).called(1);
      });
    });

    group('Animation and Lip-Sync Coordination', () {
      test('should coordinate Rive animations with character states', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Test various character states
        final states = ['listening', 'thinking', 'speaking', 'concerned', 'happy', 'explaining'];
        
        for (final state in states) {
          await characterStateNotifier.changeState(state);
        }

        // Assert
        // Verify each state triggered corresponding animation
        for (final state in states) {
          verify(mockAnimationManager.playAnimation(state)).called(1);
          verify(mockCharacterEngine.changeState(state)).called(1);
        }
      });

      test('should handle lip-sync during speaking state', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        const testMessage = 'This is a test message for lip-sync coordination.';

        // Act
        await characterStateNotifier.startSpeaking(testMessage);

        // Assert
        final state = container.read(characterStateProvider);
        expect(state.isSpeaking, isTrue);
        expect(state.currentState, 'speaking');
        expect(state.status, CharacterStatus.speaking);

        // Verify lip-sync was started
        verify(mockLipSyncService.speakWithLipSync(testMessage)).called(1);
        verify(mockAnimationManager.playAnimation('speaking')).called(1);
      });
    });

    group('Error Recovery and Resilience', () {
      test('should recover from service failures and continue operation', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Simulate service failure
        when(mockCharacterEngine.changeState('speaking')).thenThrow(Exception('Service error'));
        when(mockCharacterEngine.changeState('idle')).thenAnswer((_) async {});

        // Act - First operation fails, second succeeds
        await characterStateNotifier.changeState('speaking');
        await characterStateNotifier.changeState('idle');

        // Assert
        final finalState = container.read(characterStateProvider);
        expect(finalState.currentState, 'idle');
        expect(finalState.status, CharacterStatus.ready);
        expect(finalState.errorMessage, isNull); // Should recover from error
      });

      test('should handle rapid state changes without system failure', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Rapid state changes
        final futures = <Future>[];
        for (int i = 0; i < 20; i++) {
          futures.add(characterStateNotifier.changeState('listening'));
          futures.add(characterStateNotifier.changeState('speaking'));
        }

        // Assert - All operations should complete
        await Future.wait(futures);
        
        final finalState = container.read(characterStateProvider);
        expect(finalState.status, CharacterStatus.ready);
        expect(finalState.currentState, 'speaking'); // Last successful state
      });
    });

    group('Performance and Memory Management', () {
      test('should handle large conversation histories efficiently', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Add many messages
        for (int i = 0; i < 100; i++) {
          characterStateNotifier.addMessage('Message $i');
        }

        // Assert
        final state = container.read(characterStateProvider);
        expect(state.conversationHistory, hasLength(100));
        expect(state.lastMessageTime, isNotNull);

        // Act - Clear history
        characterStateNotifier.clearConversationHistory();

        // Assert
        final clearedState = container.read(characterStateProvider);
        expect(clearedState.conversationHistory, isEmpty);
        expect(clearedState.lastMessageTime, isNull);
      });

      test('should dispose resources correctly on cleanup', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Dispose
        characterStateNotifier.dispose();

        // Assert - Should not throw errors
        expect(() => characterStateNotifier.dispose(), returnsNormally);
      });
    });

    group('Real-world Usage Scenarios', () {
      test('should handle typical pediatric consultation flow', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Simulate typical consultation flow
        // 1. Greeting
        await characterStateNotifier.startSpeaking('Hello! I\'m Dr. Care. Welcome to our clinic.');
        await characterStateNotifier.stopSpeaking();
        
        // 2. Listening to symptoms
        await characterStateNotifier.startListening();
        await Future.delayed(const Duration(milliseconds: 100)); // Simulate listening time
        await characterStateNotifier.stopListening();
        
        // 3. Thinking about diagnosis
        await characterStateNotifier.changeState('thinking');
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 4. Explaining findings
        await characterStateNotifier.changeState('explaining');
        await characterStateNotifier.startSpeaking('Based on what you\'ve described, I think we should...');
        await characterStateNotifier.stopSpeaking();
        
        // 5. Show concern if needed
        await characterStateNotifier.changeState('concerned');
        await characterStateNotifier.startSpeaking('I want to make sure we address this properly.');
        await characterStateNotifier.stopSpeaking();
        
        // 6. End with encouragement
        await characterStateNotifier.changeEmotionalTone('encouraging');
        await characterStateNotifier.changeState('happy');
        await characterStateNotifier.startSpeaking('You\'re doing great! We\'ll get this sorted out.');
        await characterStateNotifier.stopSpeaking();
        
        // 7. Return to idle
        await characterStateNotifier.changeState('idle');

        // Assert
        final finalState = container.read(characterStateProvider);
        expect(finalState.currentState, 'idle');
        expect(finalState.currentEmotionalTone, 'encouraging');
        expect(finalState.status, CharacterStatus.ready);
        expect(finalState.conversationHistory, hasLength(4));
        expect(finalState.conversationHistory, contains('Hello! I\'m Dr. Care. Welcome to our clinic.'));
        expect(finalState.conversationHistory, contains('You\'re doing great! We\'ll get this sorted out.'));
      });

      test('should handle emergency situation with appropriate emotional response', () async {
        // Arrange
        final characterStateNotifier = container.read(characterStateProvider.notifier);
        await characterStateNotifier.initialize();

        // Act - Emergency response flow
        await characterStateNotifier.changeState('concerned');
        await characterStateNotifier.changeEmotionalTone('professional');
        await characterStateNotifier.startSpeaking('I understand this is concerning. Let me help you immediately.');
        await characterStateNotifier.stopSpeaking();
        
        await characterStateNotifier.changeState('explaining');
        await characterStateNotifier.startSpeaking('Here\'s what we need to do right now...');
        await characterStateNotifier.stopSpeaking();
        
        await characterStateNotifier.changeState('idle');

        // Assert
        final finalState = container.read(characterStateProvider);
        expect(finalState.currentState, 'idle');
        expect(finalState.currentEmotionalTone, 'professional');
        expect(finalState.conversationHistory, hasLength(2));
        expect(finalState.conversationHistory, contains('I understand this is concerning. Let me help you immediately.'));
      });
    });
  });
}
