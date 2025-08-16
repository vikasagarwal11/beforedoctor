import 'dart:math';
import 'nlu_service.dart';
import '../models/app_models.dart';

/// Mock NLU Service for UI testing
/// Simulates real natural language understanding
class MockNLUService implements NLUService {
  final Random _random = Random();

  @override
  Future<NLUResult> processText(String text) async {
    // Simulate processing delay
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));
    
    final symptoms = await extractSymptoms(text);
    final intent = await determineIntent(text);
    final response = await generateResponse(text, Audience.child);
    
    return NLUResult(
      response: response,
      symptoms: symptoms,
      intent: intent,
      confidence: 0.8 + _random.nextDouble() * 0.2,
      requiresMedicalAttention: symptoms.any((s) => s.severity == 'high'),
    );
  }

  @override
  Future<List<Symptom>> extractSymptoms(String text) async {
    final symptoms = <Symptom>[];
    
    if (text.toLowerCase().contains('tummy') || text.toLowerCase().contains('stomach')) {
      symptoms.add(const Symptom(
        name: 'Stomach pain',
        severity: 'medium',
        duration: Duration(hours: 2),
        location: 'abdomen',
      ));
    }
    
    if (text.toLowerCase().contains('fever')) {
      symptoms.add(const Symptom(
        name: 'Fever',
        severity: 'high',
        duration: Duration(hours: 4),
        location: 'body',
      ));
    }
    
    if (text.toLowerCase().contains('head')) {
      symptoms.add(const Symptom(
        name: 'Headache',
        severity: 'medium',
        duration: Duration(hours: 1),
        location: 'head',
      ));
    }
    
    if (text.toLowerCase().contains('throat')) {
      symptoms.add(const Symptom(
        name: 'Sore throat',
        severity: 'low',
        duration: Duration(hours: 6),
        location: 'throat',
      ));
    }
    
    return symptoms;
  }

  @override
  Future<UserIntent> determineIntent(String text) async {
    if (text.toLowerCase().contains('hurt') || text.toLowerCase().contains('pain')) {
      return UserIntent.symptomReport;
    }
    
    if (text.toLowerCase().contains('fever') && text.toLowerCase().contains('104')) {
      return UserIntent.emergency;
    }
    
    if (text.toLowerCase().contains('?')) {
      return UserIntent.question;
    }
    
    return UserIntent.symptomReport;
  }

  @override
  Future<String> generateResponse(String text, Audience audience) async {
    if (audience == Audience.child) {
      final responses = [
        "I understand your tummy hurts. Let me help you feel better!",
        "That sounds uncomfortable. Can you tell me more?",
        "I'm here to help. Let's figure out what's going on.",
        "Thank you for telling me. I'm thinking about the best way to help.",
        "You're doing great at explaining how you feel!",
      ];
      return responses[_random.nextInt(responses.length)];
    } else {
      final responses = [
        "I've noted the symptoms. Let me analyze this for you.",
        "Based on what you've described, here's what I'm seeing.",
        "I'll process this information and provide guidance.",
        "Thank you for the detailed description. Analyzing now.",
        "I'm reviewing the symptoms to determine next steps.",
      ];
      return responses[_random.nextInt(responses.length)];
    }
  }
}
