import 'dart:async';
import 'dart:math';
import 'voice_service.dart';

/// Mock Voice Service for UI testing
/// Simulates real voice recognition behavior
class MockVoiceService implements VoiceService {
  bool _isListening = false;
  final StreamController<VoiceResult> _resultsController = StreamController.broadcast();
  final StreamController<bool> _vadController = StreamController.broadcast();
  Timer? _vadTimer;

  @override
  bool get isListening => _isListening;

  @override
  Stream<VoiceResult> get results => _resultsController.stream;

  @override
  Stream<bool> get vadSilence => _vadController.stream;

  @override
  Future<void> startListening() async {
    _isListening = true;
    
    // Simulate VAD silence after 3 seconds
    _vadTimer = Timer(const Duration(seconds: 3), () {
      _vadController.add(true);
    });
    
    // Simulate partial results
    _simulatePartialResults();
  }

  @override
  Future<VoiceResult> stopAndTranscribe() async {
    _isListening = false;
    _vadTimer?.cancel();
    
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return mock transcription
    final mockTexts = [
      "My tummy hurts",
      "I have a fever",
      "My head hurts",
      "I feel sick",
      "My throat is sore",
    ];
    
    final random = Random();
    final text = mockTexts[random.nextInt(mockTexts.length)];
    
    return VoiceResult(
      text: text,
      isFinal: true,
      confidence: 0.85 + random.nextDouble() * 0.15,
      language: 'en',
      duration: const Duration(seconds: 3),
    );
  }

  void _simulatePartialResults() {
    if (!_isListening) return;
    
    Timer(const Duration(milliseconds: 500), () {
      if (_isListening) {
        _resultsController.add(const VoiceResult(
          text: "My...",
          isFinal: false,
          confidence: 0.7,
          duration: Duration(milliseconds: 500),
        ));
        
        Timer(const Duration(milliseconds: 800), () {
          if (_isListening) {
            _resultsController.add(const VoiceResult(
              text: "My tummy...",
              isFinal: false,
              confidence: 0.8,
              duration: Duration(milliseconds: 1300),
            ));
          }
        });
      }
    });
  }

  void dispose() {
    _vadTimer?.cancel();
    _resultsController.close();
    _vadController.close();
  }
}
