import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:logger/logger.dart';
import 'package:beforedoctor/core/services/character_interaction_engine.dart';
import 'package:beforedoctor/core/services/rive_animation_manager.dart';
import 'package:beforedoctor/core/services/lip_sync_service.dart';
import 'package:beforedoctor/core/providers/character_state_provider.dart';

// Generate mocks
@GenerateMocks([
  CharacterInteractionEngine,
  RiveAnimationManager,
  LipSyncService,
  Logger,
])
import 'character_animation_system_test.mocks.dart';

void main() {
  group('Animated Character System Tests', () {
    late MockCharacterInteractionEngine mockCharacterEngine;
    late MockRiveAnimationManager mockAnimationManager;
    late MockLipSyncService mockLipSyncService;
    late MockLogger mockLogger;
    late CharacterStateNotifier characterStateNotifier;

    setUp(() {
      mockCharacterEngine = MockCharacterInteractionEngine();
      mockAnimationManager = MockRiveAnimationManager();
      mockLipSyncService = MockLipSyncService();
      mockLogger = MockLogger();
      
      // Set up default mock behaviors
      when(mockCharacterEngine.initialize()).thenAnswer((_) async {});
      when(mockAnimationManager.initialize()).thenAnswer((_) async {});
      when(mockLipSyncService.initialize()).thenAnswer((_) async {});
      when(mockLogger.i(any)).thenReturn(null);
      when(mockLogger.d(any)).thenReturn(null);
      when(mockLogger.w(any)).thenReturn(null);
      when(mockLogger.e(any)).thenReturn(null);
    });

    group('Character State Management', () {
      test('should initialize successfully with all services', () async {
        // Arrange
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );

        // Act
        await characterStateNotifier.initialize();

        // Assert
        expect(characterStateNotifier.state.isInitialized, isTrue);
        expect(characterStateNotifier.state.status, CharacterStatus.ready);
        verify(mockCharacterEngine.initialize()).called(1);
        verify(mockAnimationManager.initialize()).called(1);
        verify(mockLipSyncService.initialize()).called(1);
      });

      test('should handle initialization errors gracefully', () async {
        // Arrange
        when(mockCharacterEngine.initialize()).thenThrow(Exception('Service unavailable'));
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );

        // Act
        await characterStateNotifier.initialize();

        // Assert
        expect(characterStateNotifier.state.isInitialized, isFalse);
        expect(characterStateNotifier.state.status, CharacterStatus.error);
        expect(characterStateNotifier.state.errorMessage, contains('Service unavailable'));
      });

      test('should change character state successfully', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        when(mockAnimationManager.playAnimation(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act
        await characterStateNotifier.changeState('speaking');

        // Assert
        expect(characterStateNotifier.state.currentState, 'speaking');
        expect(characterStateNotifier.state.status, CharacterStatus.ready);
        verify(mockCharacterEngine.changeState('speaking')).called(1);
        verify(mockAnimationManager.playAnimation('speaking')).called(1);
      });

      test('should prevent state changes when not initialized', () async {
        // Arrange
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );

        // Act
        await characterStateNotifier.changeState('speaking');

        // Assert
        expect(characterStateNotifier.state.currentState, 'idle');
        verifyNever(mockCharacterEngine.changeState(any));
        verifyNever(mockAnimationManager.playAnimation(any));
      });
    });

    group('Speech and Lip-Sync', () {
      test('should start speaking with lip-sync successfully', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        when(mockLipSyncService.speakWithLipSync(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        const testMessage = 'Hello, how are you feeling today?';

        // Act
        await characterStateNotifier.startSpeaking(testMessage);

        // Assert
        expect(characterStateNotifier.state.isSpeaking, isTrue);
        expect(characterStateNotifier.state.currentMessage, testMessage);
        expect(characterStateNotifier.state.status, CharacterStatus.speaking);
        expect(characterStateNotifier.state.conversationHistory, contains(testMessage));
        verify(mockLipSyncService.speakWithLipSync(testMessage)).called(1);
      });

      test('should stop speaking and return to idle state', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        when(mockLipSyncService.stopSpeaking()).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();
        
        // Start speaking first
        await characterStateNotifier.startSpeaking('Test message');

        // Act
        await characterStateNotifier.stopSpeaking();

        // Assert
        expect(characterStateNotifier.state.isSpeaking, isFalse);
        expect(characterStateNotifier.state.currentMessage, '');
        expect(characterStateNotifier.state.status, CharacterStatus.ready);
        verify(mockLipSyncService.stopSpeaking()).called(1);
      });

      test('should handle speech errors gracefully', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        when(mockLipSyncService.speakWithLipSync(any)).thenThrow(Exception('TTS error'));
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act
        await characterStateNotifier.startSpeaking('Test message');

        // Assert
        expect(characterStateNotifier.state.isSpeaking, isFalse);
        expect(characterStateNotifier.state.status, CharacterStatus.error);
        expect(characterStateNotifier.state.errorMessage, contains('TTS error'));
      });
    });

    group('Listening Mode', () {
      test('should start listening mode successfully', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act
        await characterStateNotifier.startListening();

        // Assert
        expect(characterStateNotifier.state.isListening, isTrue);
        expect(characterStateNotifier.state.status, CharacterStatus.listening);
        verify(mockCharacterEngine.changeState('listening')).called(1);
      });

      test('should stop listening and return to idle state', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();
        
        // Start listening first
        await characterStateNotifier.startListening();

        // Act
        await characterStateNotifier.stopListening();

        // Assert
        expect(characterStateNotifier.state.isListening, isFalse);
        expect(characterStateNotifier.state.status, CharacterStatus.ready);
        verify(mockCharacterEngine.changeState('idle')).called(1);
      });
    });

    group('Conversation Management', () {
      test('should add messages to conversation history', () {
        // Arrange
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );

        const message1 = 'Hello there!';
        const message2 = 'How can I help you?';

        // Act
        characterStateNotifier.addMessage(message1);
        characterStateNotifier.addMessage(message2);

        // Assert
        expect(characterStateNotifier.state.conversationHistory, hasLength(2));
        expect(characterStateNotifier.state.conversationHistory, contains(message1));
        expect(characterStateNotifier.state.conversationHistory, contains(message2));
        expect(characterStateNotifier.state.lastMessageTime, isNotNull);
      });

      test('should clear conversation history', () {
        // Arrange
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        characterStateNotifier.addMessage('Test message');

        // Act
        characterStateNotifier.clearConversationHistory();

        // Assert
        expect(characterStateNotifier.state.conversationHistory, isEmpty);
        expect(characterStateNotifier.state.lastMessageTime, isNull);
      });
    });

    group('Emotional Tone Management', () {
      test('should change emotional tone successfully', () async {
        // Arrange
        when(mockCharacterEngine.changeEmotionalTone(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act
        await characterStateNotifier.changeEmotionalTone('encouraging');

        // Assert
        expect(characterStateNotifier.state.currentEmotionalTone, 'encouraging');
        expect(characterStateNotifier.state.lastToneChange, isNotNull);
        verify(mockCharacterEngine.changeEmotionalTone('encouraging')).called(1);
      });
    });

    group('State Transitions', () {
      test('should handle multiple state transitions correctly', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        when(mockAnimationManager.playAnimation(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act - Test state transition sequence
        await characterStateNotifier.changeState('listening');
        await characterStateNotifier.changeState('thinking');
        await characterStateNotifier.changeState('speaking');
        await characterStateNotifier.changeState('idle');

        // Assert
        expect(characterStateNotifier.state.currentState, 'idle');
        verify(mockCharacterEngine.changeState('listening')).called(1);
        verify(mockCharacterEngine.changeState('thinking')).called(1);
        verify(mockCharacterEngine.changeState('speaking')).called(1);
        verify(mockCharacterEngine.changeState('idle')).called(1);
      });

      test('should maintain conversation history during state changes', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        when(mockAnimationManager.playAnimation(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Add some conversation history
        characterStateNotifier.addMessage('Message 1');
        characterStateNotifier.addMessage('Message 2');

        // Act
        await characterStateNotifier.changeState('speaking');
        await characterStateNotifier.changeState('idle');

        // Assert
        expect(characterStateNotifier.state.conversationHistory, hasLength(2));
        expect(characterStateNotifier.state.conversationHistory, contains('Message 1'));
        expect(characterStateNotifier.state.conversationHistory, contains('Message 2'));
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenThrow(Exception('Service error'));
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act
        await characterStateNotifier.changeState('speaking');

        // Assert
        expect(characterStateNotifier.state.status, CharacterStatus.error);
        expect(characterStateNotifier.state.errorMessage, contains('Service error'));
      });

      test('should recover from errors on successful operations', () async {
        // Arrange
        when(mockCharacterEngine.changeState('speaking')).thenThrow(Exception('Service error'));
        when(mockCharacterEngine.changeState('idle')).thenAnswer((_) async {});
        when(mockAnimationManager.playAnimation(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act - First operation fails
        await characterStateNotifier.changeState('speaking');
        // Second operation succeeds
        await characterStateNotifier.changeState('idle');

        // Assert
        expect(characterStateNotifier.state.currentState, 'idle');
        expect(characterStateNotifier.state.status, CharacterStatus.ready);
        expect(characterStateNotifier.state.errorMessage, isNull);
      });
    });

    group('Performance and Memory', () {
      test('should dispose resources correctly', () {
        // Arrange
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );

        // Act
        characterStateNotifier.dispose();

        // Assert - Verify that dispose doesn't throw errors
        expect(() => characterStateNotifier.dispose(), returnsNormally);
      });

      test('should handle rapid state changes without errors', () async {
        // Arrange
        when(mockCharacterEngine.changeState(any)).thenAnswer((_) async {});
        when(mockAnimationManager.playAnimation(any)).thenAnswer((_) async {});
        
        characterStateNotifier = CharacterStateNotifier(
          mockCharacterEngine,
          mockAnimationManager,
          mockLipSyncService,
        );
        await characterStateNotifier.initialize();

        // Act - Rapid state changes
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(characterStateNotifier.changeState('listening'));
          futures.add(characterStateNotifier.changeState('speaking'));
        }

        // Assert - All operations should complete without errors
        await Future.wait(futures);
        expect(characterStateNotifier.state.status, CharacterStatus.ready);
      });
    });
  });
}
