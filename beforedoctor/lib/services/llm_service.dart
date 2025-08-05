import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:beforedoctor/services/model_selector_service.dart';
import '../core/services/logging_service.dart';

class LLMService {
  final ModelSelectorService modelSelector = ModelSelectorService();
  final LoggingService _loggingService = LoggingService();

  // Use dotenv for environment variables (more secure than Platform.environment)
  final _openaiKey = dotenv.env['OPENAI_API_KEY'];
  final _grokKey = dotenv.env['XAI_GROK_API_KEY'];
  final _timeout = const Duration(seconds: 10);

  // Initialize the service
  Future<void> initialize() async {
    await modelSelector.initialize();
  }

  // Main method for getting AI response with auto-selection and fallback
  Future<String> getAIResponse(String prompt) async {
    final startTime = DateTime.now();
    
    // Get the best model based on performance history
    final primaryModel = modelSelector.getBestModel();
    final fallbackModel = primaryModel == AIModelType.openai ? AIModelType.grok : AIModelType.openai;
    
    final recommendation = modelSelector.getRecommendationWithConfidence();
    print('🤖 Model Selection: ${recommendation['recommendedModel']} (${recommendation['confidence']} confidence)');

    // Try primary model
    final response = await _callModel(prompt, primaryModel);
    if (response['success']) {
      // Log successful response
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await _loggingService.logAIPerformance(
        model: primaryModel.name,
        latency: responseTime,
        success: true,
        promptType: 'medical_symptom',
      );
      return response['text'];
    }

    // Try fallback model
    final fallbackResponse = await _callModel(prompt, fallbackModel);
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
    if (fallbackResponse['success']) {
      await _loggingService.logAIPerformance(
        model: fallbackModel.name,
        latency: responseTime,
        success: true,
        promptType: 'medical_symptom',
      );
      return fallbackResponse['text'];
    }

    // If both fail, return fallback response
    await _loggingService.logAIPerformance(
      model: 'fallback',
      latency: responseTime,
      success: false,
      promptType: 'medical_symptom',
    );
    
    return generateFallbackResponse(prompt);
  }

  // Public method for calling specific models
  Future<String> callOpenAI(String prompt) async {
    final response = await _callModel(prompt, AIModelType.openai);
    return response['text'] ?? 'No response from OpenAI';
  }

  Future<String> callGrok(String prompt) async {
    final response = await _callModel(prompt, AIModelType.grok);
    return response['text'] ?? 'No response from Grok';
  }

  // Call a specific model with error handling
  Future<Map<String, dynamic>> _callModel(String prompt, AIModelType model) async {
    final start = DateTime.now();
    try {
      final result = await _requestModel(prompt, model).timeout(_timeout);
      final latency = DateTime.now().difference(start).inMilliseconds;
      
      // Record the result for future model selection
      await modelSelector.recordResult(
        model: model,
        success: true,
        latencyMs: latency,
      );
      
      return {
        'success': true,
        'text': result,
      };
    } catch (e) {
      final latency = DateTime.now().difference(start).inMilliseconds;
      
      // Record failure
      await modelSelector.recordResult(
        model: model,
        success: false,
        latencyMs: latency,
      );
      
      return {
        'success': false,
        'text': null,
      };
    }
  }

  // Route to the appropriate model
  Future<String> _requestModel(String prompt, AIModelType model) async {
    if (model == AIModelType.openai) {
      return _callOpenAI(prompt);
    } else {
      return _callGrok(prompt);
    }
  }

  // Call OpenAI API
  Future<String> _callOpenAI(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openaiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o", // Updated to latest model
        "messages": [
          {"role": "system", "content": "You are a board-certified pediatrician assistant. Provide accurate, age-appropriate medical guidance while always recommending consulting a doctor for serious concerns."},
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }

  // Call Grok API with correct endpoint
  Future<String> _callGrok(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.grok.x.ai/v1/chat/completions'), // Correct Grok API endpoint
      headers: {
        'Authorization': 'Bearer $_grokKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "grok-1",
        "messages": [
          {"role": "system", "content": "You are a board-certified pediatrician assistant. Provide accurate, age-appropriate medical guidance while always recommending consulting a doctor for serious concerns."},
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Grok API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }

  // Fallback response for when APIs are unavailable
  String generateFallbackResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('fever')) {
      return 'For fever in children:\n• Monitor temperature every 4-6 hours\n• Keep child hydrated\n• Use acetaminophen or ibuprofen as directed\n• Contact doctor if fever >104°F or lasts >3 days\n\n⚠️ Always consult your pediatrician for personalized advice.';
    } else if (lowerPrompt.contains('cough')) {
      return 'For cough in children:\n• Ensure adequate hydration\n• Use honey (for children >1 year)\n• Consider humidifier\n• Contact doctor if cough is severe or persistent\n\n⚠️ Always consult your pediatrician for personalized advice.';
    } else if (lowerPrompt.contains('vomit')) {
      return 'For vomiting in children:\n• Start with small sips of clear fluids\n• Gradually increase fluid intake\n• Watch for signs of dehydration\n• Contact doctor if vomiting persists >24 hours\n\n⚠️ Always consult your pediatrician for personalized advice.';
    } else if (lowerPrompt.contains('diarrhea')) {
      return 'For diarrhea in children:\n• Maintain hydration with oral rehydration solutions\n• Continue normal diet if tolerated\n• Watch for signs of dehydration\n• Contact doctor if severe or bloody\n\n⚠️ Always consult your pediatrician for personalized advice.';
    } else {
      return 'Based on the symptoms described, I recommend:\n• Monitor the child closely\n• Keep a symptom diary\n• Contact your pediatrician if symptoms worsen\n• Seek immediate care for severe symptoms\n\n⚠️ Always consult your pediatrician for personalized advice.';
    }
  }

  // Legacy method for backward compatibility
  Future<String> getLLMResponse(String prompt) async {
    return await getAIResponse(prompt);
  }

  // Get model performance summary
  Map<String, dynamic> getModelPerformanceSummary() {
    return modelSelector.getPerformanceSummary();
  }

  // Get model recommendation with confidence
  Map<String, dynamic> getModelRecommendation() {
    return modelSelector.getRecommendationWithConfidence();
  }

  // Reset model performance stats
  Future<void> resetModelStats() async {
    await modelSelector.resetStats();
  }

  // Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    return await _loggingService.getAnalyticsSummary();
  }

  // Dispose resources
  Future<void> dispose() async {
    await modelSelector.dispose();
  }
} 