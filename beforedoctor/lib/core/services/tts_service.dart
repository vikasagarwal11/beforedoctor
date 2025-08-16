/// Text-to-Speech Service Interface
/// Handles voice output and speech synthesis
abstract class TTSService {
  /// Speak the given text
  Future<void> speak(String text);
  
  /// Stop current speech
  Future<void> stop();
  
  /// Whether currently speaking
  bool get isSpeaking;
  
  /// Stream of speech events
  Stream<TTSEvent> get events;
  
  /// Set voice parameters (age, gender, language)
  Future<void> setVoice({
    String? language,
    String? gender,
    int? age,
  });
}

/// TTS event types
enum TTSEventType {
  started,
  paused,
  resumed,
  completed,
  error,
}

/// TTS event
class TTSEvent {
  final TTSEventType type;
  final String? text;
  final String? error;
  final Duration? duration;

  const TTSEvent({
    required this.type,
    this.text,
    this.error,
    this.duration,
  });
}
