import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logging_service.dart';
import 'enhanced_model_selector.dart';

class LLMService {
  final _openaiApiKey = dotenv.env['OPENAI_API_KEY'];
  final _grokApiKey = dotenv.env['XAI_GROK_API_KEY'];
  final _timeout = Duration(seconds: 10); // Set timeout threshold
  final _qualityScores = {'openai': 0.0, 'grok': 0.0};
  final _loggingService = LoggingService();
  final _modelSelector = EnhancedModelSelector.instance;

  Future<String> getLLMResponse(String prompt) async {
    final startTime = DateTime.now();
    
    // Get the best model based on performance history
    final bestModel = _modelSelector.getBestModel();
    final recommendation = _modelSelector.getRecommendationWithConfidence();
    
    print('🤖 Model Selection: ${recommendation['recommendedModel']} (${recommendation['confidence']} confidence)');
    
    String response;
    String modelUsed;
    int latencyMs = 0;
    bool success = false;

    try {
      switch (bestModel) {
        case AIModelType.openai:
          final result = await _queryOpenAI(prompt);
          response = result['response'];
          modelUsed = 'openai';
          latencyMs = result['latency'];
          success = response.isNotEmpty;
          break;
        case AIModelType.grok:
          final result = await _queryGrok(prompt);
          response = result['response'];
          modelUsed = 'grok';
          latencyMs = result['latency'];
          success = response.isNotEmpty;
          break;
      }

      // Record the result for future model selection
      await _modelSelector.recordResult(
        model: bestModel,
        success: success,
        latencyMs: latencyMs,
      );

      // Log the interaction
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await _loggingService.logAIPerformance(
        model: modelUsed,
        latency: responseTime,
        success: success,
        promptType: 'medical_symptom',
      );

      return response;
    } catch (e) {
      // Record failure
      await _modelSelector.recordResult(
        model: bestModel,
        success: false,
        latencyMs: _timeout.inMilliseconds,
      );

      // Try fallback
      return generateFallbackResponse(prompt);
    }
  }

  Future<Map<String, dynamic>> _queryOpenAI(String prompt) async {
    final start = DateTime.now();
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_openaiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );
      final duration = DateTime.now().difference(start).inMilliseconds;
      final data = json.decode(res.body);
      final content = data['choices']?[0]['message']?['content'] ?? 'No response.';
      return {
        'provider': 'openai',
        'response': content,
        'latency': duration,
      };
    } catch (_) {
      return {'provider': 'openai', 'response': '', 'latency': _timeout.inMilliseconds};
    }
  }

  Future<Map<String, dynamic>> _queryGrok(String prompt) async {
    final start = DateTime.now();
    try {
      final res = await http.post(
        Uri.parse('https://api.grok.x.ai/v1/chat/completions'), // Adjust if different
        headers: {
          'Authorization': 'Bearer $_grokApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'grok-1',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );
      final duration = DateTime.now().difference(start).inMilliseconds;
      final data = json.decode(res.body);
      final content = data['choices']?[0]['message']?['content'] ?? 'No response.';
      return {
        'provider': 'grok',
        'response': content,
        'latency': duration,
      };
    } catch (_) {
      return {'provider': 'grok', 'response': '', 'latency': _timeout.inMilliseconds};
    }
  }

  Future<Map<String, dynamic>> _rankModels(String prompt, Map<String, dynamic> initial) async {
    final all = [await _queryOpenAI(prompt), await _queryGrok(prompt)];
    all.sort((a, b) => a['latency'].compareTo(b['latency']));
    final best = all.firstWhere((model) => model['response'].isNotEmpty, orElse: () => initial);
    
    // Store score logic for future logging or analytics
    _qualityScores[best['provider']] = 1.0;
    return best;
  }

  // Legacy methods for backward compatibility with existing voice logger
  Future<String> getSuggestion(String prompt) async {
    return await getLLMResponse(prompt);
  }

  Future<String> callOpenAI(String prompt) async {
    final startTime = DateTime.now();
    final result = await _queryOpenAI(prompt);
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Record the result
    await _modelSelector.recordResult(
      model: AIModelType.openai,
      success: result['response'].isNotEmpty,
      latencyMs: result['latency'],
    );
    
    // Log the interaction
    await _loggingService.logAIPerformance(
      model: 'openai',
      latency: responseTime,
      success: result['response'].isNotEmpty,
      promptType: 'medical_symptom',
    );
    
    return result['response'];
  }

  Future<String> callGrok(String prompt) async {
    final startTime = DateTime.now();
    final result = await _queryGrok(prompt);
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Record the result
    await _modelSelector.recordResult(
      model: AIModelType.grok,
      success: result['response'].isNotEmpty,
      latencyMs: result['latency'],
    );
    
    // Log the interaction
    await _loggingService.logAIPerformance(
      model: 'grok',
      latency: responseTime,
      success: result['response'].isNotEmpty,
      promptType: 'medical_symptom',
    );
    
    return result['response'];
  }
  
  // Fallback response for when APIs are unavailable
  String generateFallbackResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('fever')) {
      return 'For fever in children:\n• Monitor temperature every 4-6 hours\n• Keep child hydrated\n• Use acetaminophen or ibuprofen as directed\n• Contact doctor if fever >104°F or lasts >3 days';
    } else if (lowerPrompt.contains('cough')) {
      return 'For cough in children:\n• Ensure adequate hydration\n• Use honey (for children >1 year)\n• Consider humidifier\n• Contact doctor if cough is severe or persistent';
    } else if (lowerPrompt.contains('vomit')) {
      return 'For vomiting in children:\n• Start with small sips of clear fluids\n• Gradually increase fluid intake\n• Watch for signs of dehydration\n• Contact doctor if vomiting persists >24 hours';
    } else if (lowerPrompt.contains('diarrhea')) {
      return 'For diarrhea in children:\n• Maintain hydration with oral rehydration solutions\n• Continue normal diet if tolerated\n• Watch for signs of dehydration\n• Contact doctor if severe or bloody';
    } else {
      return 'Based on the symptoms described, I recommend:\n• Monitor the child closely\n• Keep a symptom diary\n• Contact your pediatrician if symptoms worsen\n• Seek immediate care for severe symptoms';
    }
  }

  // Get quality scores for analytics
  Map<String, double> getQualityScores() {
    return Map.from(_qualityScores);
  }

  // Reset quality scores
  void resetQualityScores() {
    _qualityScores['openai'] = 0.0;
    _qualityScores['grok'] = 0.0;
  }

  // Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    return await _loggingService.getAnalyticsSummary();
  }

  // Get model performance summary
  Map<String, dynamic> getModelPerformanceSummary() {
    return _modelSelector.getPerformanceSummary();
  }

  // Get model recommendation with confidence
  Map<String, dynamic> getModelRecommendation() {
    return _modelSelector.getRecommendationWithConfidence();
  }

  // Initialize the enhanced model selector
  Future<void> initialize() async {
    await _modelSelector.initialize();
  }

  // Reset model performance stats
  Future<void> resetModelStats() async {
    await _modelSelector.resetStats();
  }
} 