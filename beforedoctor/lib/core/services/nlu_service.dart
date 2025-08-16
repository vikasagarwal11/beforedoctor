import '../models/app_models.dart';

/// Natural Language Understanding Service Interface
/// Handles symptom extraction, intent recognition, and response generation
abstract class NLUService {
  /// Process voice input and generate appropriate response
  Future<NLUResult> processText(String text);
  
  /// Extract symptoms from voice input
  Future<List<Symptom>> extractSymptoms(String text);
  
  /// Determine user intent (symptom report, question, etc.)
  Future<UserIntent> determineIntent(String text);
  
  /// Generate age-appropriate response
  Future<String> generateResponse(String text, Audience audience);
}

/// Result from NLU processing
class NLUResult {
  final String response;
  final List<Symptom> symptoms;
  final UserIntent intent;
  final double confidence;
  final bool requiresMedicalAttention;

  const NLUResult({
    required this.response,
    required this.symptoms,
    required this.intent,
    required this.confidence,
    required this.requiresMedicalAttention,
  });
}

/// Extracted symptom information
class Symptom {
  final String name;
  final String severity;
  final Duration duration;
  final String location;
  final Map<String, dynamic> metadata;

  const Symptom({
    required this.name,
    required this.severity,
    required this.duration,
    required this.location,
    this.metadata = const {},
  });
}

/// User intent classification
enum UserIntent {
  symptomReport,
  question,
  emergency,
  general,
  unknown,
}
