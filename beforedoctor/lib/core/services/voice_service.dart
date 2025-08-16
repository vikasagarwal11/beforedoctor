import 'dart:async';

/// Voice Recognition Service Interface
/// Handles ASR (Automatic Speech Recognition) and VAD (Voice Activity Detection)
abstract class VoiceService {
  /// Start listening for voice input
  Future<void> startListening();
  
  /// Stop listening and transcribe what was heard
  Future<VoiceResult> stopAndTranscribe();
  
  /// Stream of voice recognition results
  Stream<VoiceResult> get results;
  
  /// Whether currently listening
  bool get isListening;
  
  /// Voice Activity Detection - when user stops speaking
  Stream<bool> get vadSilence;
}

/// Result from voice recognition
class VoiceResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final String? language;
  final Duration duration;

  const VoiceResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
    this.language,
    required this.duration,
  });
}
