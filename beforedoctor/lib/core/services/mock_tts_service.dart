import 'dart:async';
import 'dart:math';
import 'tts_service.dart';

/// Mock TTS Service for UI testing
/// Simulates real text-to-speech behavior
class MockTTSService implements TTSService {
  bool _isSpeaking = false;
  final StreamController<TTSEvent> _eventsController = StreamController.broadcast();
  Timer? _speechTimer;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<TTSEvent> get events => _eventsController.stream;

  @override
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    
    _isSpeaking = true;
    
    // Simulate speech start
    _eventsController.add(TTSEvent(
      type: TTSEventType.started,
      text: text,
    ));
    
    // Calculate speech duration (rough estimate: 150 words per minute)
    final wordCount = text.split(' ').length;
    final duration = Duration(milliseconds: (wordCount * 400).round());
    
    // Simulate speech completion
    _speechTimer = Timer(duration, () {
      _isSpeaking = false;
      _eventsController.add(TTSEvent(
        type: TTSEventType.completed,
        text: text,
        duration: duration,
      ));
    });
  }

  @override
  Future<void> stop() async {
    _speechTimer?.cancel();
    _isSpeaking = false;
    
    _eventsController.add(const TTSEvent(
      type: TTSEventType.paused,
    ));
  }

  @override
  Future<void> setVoice({
    String? language,
    String? gender,
    int? age,
  }) async {
    // Mock implementation - no actual voice changes
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void dispose() {
    _speechTimer?.cancel();
    _eventsController.close();
  }
}
