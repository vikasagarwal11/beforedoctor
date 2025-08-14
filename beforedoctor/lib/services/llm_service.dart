// Filename: lib/services/llm_service.dart
//
// Unified LLM service that merges functionality from your prior two files:
// 1) lib/core/services/llm_service.dart
// 2) lib/services/llm_service.dart
//
// - OpenAI + Grok via AppConfig (endpoints, models, temps, timeouts)
// - Adapter to work with EnhancedModelSelector OR ModelSelectorService
// - Strict-JSON prompting + robust JSON extraction & normalization for UI
// - Retries with backoff; clearer provider error logs
// - Optional "hedged" parallel mode (fastest success wins)
// - Backward compatible methods (getLLMResponse, callOpenAI, etc.)
// - LoggingService integration for analytics
// - TranslationService hook preloaded for future multi-lingual
//
// Drop-in ready with compilation fix.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Config + shared services
import '../core/config/app_config.dart';
import '../core/services/logging_service.dart';
import 'translation_service.dart';

// Model selectors (both supported via adapters)
import '../core/services/enhanced_model_selector.dart' as enhanced;
import 'model_selector_service.dart' as basic;

final AppConfig _config = AppConfig.instance;

/// Local enum (internal to this file) - fixes compilation issues
enum AIModelType { openai, grok }

/// Selector adapter interface
abstract class _ModelSelectorAdapter {
  Future<void> initialize();
  Future<void> dispose();
  Future<void> resetStats();

  Future<void> recordResult({
    required AIModelType model,
    required bool success,
    required int latencyMs,
  });

  AIModelType getBestModel();
  Map<String, dynamic> getPerformanceSummary();
  Map<String, dynamic> getRecommendationWithConfidence();
}

/// ===== EnhancedModelSelector adapter (explicit enum mapping) =====
class _EnhancedAdapter implements _ModelSelectorAdapter {
  final selector = enhanced.EnhancedModelSelector.instance;

  // Map local -> enhanced
  enhanced.AIModelType _toEnhanced(AIModelType t) {
    return t == AIModelType.openai
        ? enhanced.AIModelType.openai
        : enhanced.AIModelType.grok;
  }

  // Map enhanced -> local
  AIModelType _fromEnhanced(enhanced.AIModelType t) {
    return t == enhanced.AIModelType.openai
        ? AIModelType.openai
        : AIModelType.grok;
  }

  @override
  Future<void> initialize() => selector.initialize();

  @override
  Future<void> dispose() async {
    // no-op if not implemented in the selector
  }

  @override
  Future<void> resetStats() => selector.resetStats();

  @override
  Future<void> recordResult({
    required AIModelType model,
    required bool success,
    required int latencyMs,
  }) {
    return selector.recordResult(
      model: _toEnhanced(model),
      success: success,
      latencyMs: latencyMs,
    );
  }

  @override
  AIModelType getBestModel() {
    final em = selector.getBestModel(); // enhanced.AIModelType
    return _fromEnhanced(em);
  }

  @override
  Map<String, dynamic> getPerformanceSummary() => selector.getPerformanceSummary();

  @override
  Map<String, dynamic> getRecommendationWithConfidence() =>
      selector.getRecommendationWithConfidence();
}

/// ===== ModelSelectorService adapter (explicit enum mapping) =====
class _BasicAdapter implements _ModelSelectorAdapter {
  final selector = basic.ModelSelectorService.instance;

  // Map local -> basic
  basic.AIModelType _toBasic(AIModelType t) {
    return t == AIModelType.openai
        ? basic.AIModelType.openai
        : basic.AIModelType.grok;
  }

  // Map basic -> local
  AIModelType _fromBasic(basic.AIModelType t) {
    return t == basic.AIModelType.openai
        ? AIModelType.openai
        : AIModelType.grok;
  }

  @override
  Future<void> initialize() => selector.initialize();

  @override
  Future<void> dispose() => selector.dispose();

  @override
  Future<void> resetStats() => selector.resetStats();

  @override
  Future<void> recordResult({
    required AIModelType model,
    required bool success,
    required int latencyMs,
  }) {
    return selector.recordResult(
      model: _toBasic(model),
      success: success,
      latencyMs: latencyMs,
    );
  }

  @override
  AIModelType getBestModel() {
    final bm = selector.getBestModel(); // basic.AIModelType
    return _fromBasic(bm);
  }

  @override
  Map<String, dynamic> getPerformanceSummary() => selector.getPerformanceSummary();

  @override
  Map<String, dynamic> getRecommendationWithConfidence() =>
      selector.getRecommendationWithConfidence();
}

class LLMService {
  // Keys from .env (via AppConfig/FlutterDotEnv)
  final String _openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _grokKey = dotenv.env['XAI_GROK_API_KEY'] ?? '';

  // Timeouts (AppConfig)
  Duration get _timeout => Duration(seconds: _config.openaiTimeout);

  // Services
  final LoggingService _loggingService = LoggingService();
  final TranslationService _translationService = TranslationService();

  // Choose which selector to use (prefer Enhanced)
  late final _ModelSelectorAdapter _selector;

  // Optional simple quality scores
  final Map<String, double> _qualityScores = {'openai': 0.0, 'grok': 0.0};

  LLMService() {
    // Use Enhanced selector by default; swap to Basic if you prefer.
    _selector = _EnhancedAdapter();
    // _selector = _BasicAdapter();
  }

  // ---------- Lifecycle ----------
  Future<void> initialize() async {
    await _selector.initialize();
    await _translationService.preloadCommonLanguages();
  }

  Future<void> dispose() async {
    await _selector.dispose();
  }

  // ---------- Public API (backward compatibility) ----------

  Future<String> getLLMResponse(String prompt) async {
    final result = await getAIResponse(prompt);
    return (result['response'] as String?) ?? '';
  }

  Future<String> getAIResponseSimple(String prompt) async {
    final r = await getAIResponse(prompt);
    return (r['response'] as String?) ?? '';
  }

  Future<String> getSuggestion(String prompt) => getLLMResponse(prompt);

  Future<String> callOpenAI(String prompt) async {
    final start = DateTime.now();
    final text = await _callOpenAI(prompt);
    final lat = DateTime.now().difference(start).inMilliseconds;

    await _selector.recordResult(model: AIModelType.openai, success: text.isNotEmpty, latencyMs: lat);
    await _loggingService.logAIPerformance(
      model: 'openai',
      latency: lat,
      success: text.isNotEmpty,
      promptType: 'medical_symptom',
    );
    return text;
  }

  Future<String> callGrok(String prompt) async {
    final start = DateTime.now();
    final text = await _callGrok(prompt);
    final lat = DateTime.now().difference(start).inMilliseconds;

    await _selector.recordResult(model: AIModelType.grok, success: text.isNotEmpty, latencyMs: lat);
    await _loggingService.logAIPerformance(
      model: 'grok',
      latency: lat,
      success: text.isNotEmpty,
      promptType: 'medical_symptom',
    );
    return text;
  }

  // ---------- Preferred modern call (structured + text) ----------

  /// Returns:
  /// {
  ///   'response': String,
  ///   'model_used': 'openai'|'grok'|'fallback',
  ///   'latency_ms': int,
  ///   'success': bool,
  ///   'structured': Map<String,dynamic>?   // normalized for AIResultsWidget
  /// }
  Future<Map<String, dynamic>> getAIResponse(
    String prompt, {
    String? symptom,
    String? originalTranscript,
    bool askForJson = true,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
  }) async {
    final startTime = DateTime.now();

    final primary = _selector.getBestModel();
    final fallback = primary == AIModelType.openai ? AIModelType.grok : AIModelType.openai;

    // Try primary
    final p = await _callModel(
      prompt,
      primary,
      askForJson: askForJson,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
    if (p['success'] == true) {
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      await _loggingService.logAIPerformance(
        model: _name(primary),
        latency: latency,
        success: true,
        promptType: 'medical_symptom',
      );
      return {
        'response': p['text'],
        'model_used': _name(primary),
        'latency_ms': latency,
        'success': true,
        'structured': p['structured'],
      };
    }

    // Fallback
    final f = await _callModel(
      prompt,
      fallback,
      askForJson: askForJson,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
    final latency = DateTime.now().difference(startTime).inMilliseconds;

    if (f['success'] == true) {
      await _loggingService.logAIPerformance(
        model: _name(fallback),
        latency: latency,
        success: true,
        promptType: 'medical_symptom',
      );
      return {
        'response': f['text'],
        'model_used': _name(fallback),
        'latency_ms': latency,
        'success': true,
        'structured': f['structured'],
      };
    }

    // Both failed
    await _loggingService.logAIPerformance(
      model: 'fallback',
      latency: latency,
      success: false,
      promptType: 'medical_symptom',
    );

    final fb = generateFallbackResponse(prompt);
    return {
      'response': fb,
      'model_used': 'fallback',
      'latency_ms': latency,
      'success': false,
      'structured': null,
    };
  }

  /// Optional "hedged" version: calls both providers in parallel; returns first success.
  Future<Map<String, dynamic>> getAIResponseHedged(
    String prompt, {
    bool askForJson = true,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
  }) async {
    final start = DateTime.now();
    final a = _callModel(
      prompt,
      AIModelType.openai,
      askForJson: askForJson,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
    final b = _callModel(
      prompt,
      AIModelType.grok,
      askForJson: askForJson,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );

    Map<String, dynamic> winner = await Future.any([a, b]);
    if (winner['success'] != true) {
      winner = identical(winner, await a) ? await b : await a;
    }

    final latency = DateTime.now().difference(start).inMilliseconds;
    final modelUsed = winner['success'] == true ? (winner['provider'] ?? 'unknown') : 'fallback';

    if (winner['success'] == true) {
      await _loggingService.logAIPerformance(
        model: modelUsed,
        latency: latency,
        success: true,
        promptType: 'medical_symptom',
      );
      return {
        'response': winner['text'],
        'model_used': modelUsed,
        'latency_ms': latency,
        'success': true,
        'structured': winner['structured'],
        'hedged': true,
      };
    }

    final fb = generateFallbackResponse(prompt);
    return {
      'response': fb,
      'model_used': 'fallback',
      'latency_ms': latency,
      'success': false,
      'structured': null,
      'hedged': true,
    };
  }

  // ---------- Internals ----------

  Future<Map<String, dynamic>> _callModel(
    String prompt,
    AIModelType model, {
    required bool askForJson,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
  }) async {
    final start = DateTime.now();
    try {
      final text = await _withRetry<String>(
        () => _requestModel(
          prompt,
          model,
          askForJson: askForJson,
          systemPrompt: systemPrompt,
          maxTokens: maxTokens,
          temperature: temperature,
        ).timeout(_timeout),
      );
      final latency = DateTime.now().difference(start).inMilliseconds;

      await _selector.recordResult(model: model, success: true, latencyMs: latency);

      Map<String, dynamic>? structured;
      if (askForJson) {
        structured = _extractJsonFromText(text) ?? _tryMiniParser(text);
        if (structured != null) structured = _normalizeStructured(structured);
      }

      if (structured != null && structured.isNotEmpty) {
        _qualityScores[_name(model)] = (_qualityScores[_name(model)] ?? 0) + 0.2;
      }

      return {
        'success': true,
        'text': text,
        'structured': structured,
        'provider': _name(model),
      };
    } catch (e) {
      final latency = DateTime.now().difference(start).inMilliseconds;
      await _selector.recordResult(model: model, success: false, latencyMs: latency);
      return {
        'success': false,
        'text': null,
        'structured': null,
        'provider': _name(model),
      };
    }
  }

  Future<String> _requestModel(
    String prompt,
    AIModelType model, {
    required bool askForJson,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
  }) {
    return (model == AIModelType.openai)
        ? _callOpenAI(prompt,
            askForJson: askForJson,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens,
            temperature: temperature)
        : _callGrok(prompt,
            askForJson: askForJson,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens,
            temperature: temperature);
  }

  // ----------- Provider calls -----------

  Future<String> _callOpenAI(
    String prompt, {
    bool askForJson = false,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
  }) async {
    if (_openaiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY');
    }

    final body = {
      "model": _config.openaiModel,
      "temperature": (temperature ?? _config.openaiTemperature),
      if (maxTokens != null) "max_tokens": maxTokens,
      "messages": _buildMessages(prompt, askForJson, systemOverride: systemPrompt),
    };

    final res = await http.post(
      Uri.parse(_config.openaiApiEndpoint),
      headers: {
        'Authorization': 'Bearer $_openaiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'OpenAI API error: ${res.statusCode} (${_config.openaiModel}) @ ${_config.openaiApiEndpoint} - ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return decoded['choices']?[0]?['message']?['content']?.toString() ?? '';
  }

  Future<String> _callGrok(
    String prompt, {
    bool askForJson = false,
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
  }) async {
    if (_grokKey.isEmpty) {
      throw Exception('Missing XAI_GROK_API_KEY');
    }

    final body = {
      "model": _config.xaiGrokModel,
      "temperature": (temperature ?? _config.xaiGrokTemperature),
      if (maxTokens != null) "max_tokens": maxTokens,
      "messages": _buildMessages(prompt, askForJson, systemOverride: systemPrompt),
    };

    final res = await http.post(
      Uri.parse(_config.xaiGrokApiEndpoint),
      headers: {
        'Authorization': 'Bearer $_grokKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      // 404 is often model or endpoint mismatch—this log makes it obvious.
      throw Exception(
          'Grok API error: ${res.statusCode} (${_config.xaiGrokModel}) @ ${_config.xaiGrokApiEndpoint} - ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return decoded['choices']?[0]?['message']?['content']?.toString() ?? '';
  }

  // ----------- Prompt builder -----------

  List<Map<String, String>> _buildMessages(
    String userPrompt,
    bool askForJson, {
    String? systemOverride,
  }) {
    if (!askForJson) {
      return [
        {
          "role": "system",
          "content": systemOverride ??
              "You are a board-certified pediatric assistant. Be concise, safe, and defer to clinicians for serious concerns."
        },
        {"role": "user", "content": userPrompt},
      ];
    }

    final system = systemOverride ??
        '''
You are a pediatric triage assistant. Respond with STRICT JSON ONLY (no prose) using this schema:

{
  "predicted_symptom": "string",               
  "risk_level": "low|medium|high",
  "ai_insights": {
    "symptom_insight": "string",
    "urgency": "string",                    
    "action_required": true,                
    "treatment_suggestions": ["string"]    
  },
  "confidence_score": 0.0                   
}

No explanations. No markdown. Output JSON object only.
''';

    return [
      {"role": "system", "content": system},
      {"role": "user", "content": userPrompt},
    ];
  }

  // ----------- Retry with backoff -----------

  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 2,
    Duration baseDelay = const Duration(milliseconds: 300),
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        final jitterMs = 100 + (DateTime.now().microsecondsSinceEpoch % 200);
        final delay = baseDelay * attempt + Duration(milliseconds: jitterMs);
        await Future.delayed(delay);
      }
    }
  }

  // ----------- JSON extraction & normalization -----------

  Map<String, dynamic>? _extractJsonFromText(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final candidate = text.substring(start, end + 1).trim();
        final map = jsonDecode(candidate);
        if (map is Map<String, dynamic>) return map;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _tryMiniParser(String text) {
    if (text.trim().isEmpty) return null;

    String risk = 'medium';
    if (RegExp(r'\bhigh\b', caseSensitive: false).hasMatch(text)) risk = 'high';
    if (RegExp(r'\blow\b', caseSensitive: false).hasMatch(text)) risk = 'low';

    return {
      "predicted_symptom": "unknown",
      "risk_level": risk,
      "ai_insights": {
        "symptom_insight": text.length > 220 ? '${text.substring(0, 220)}...' : text,
        "urgency": risk == 'high'
            ? 'ER now'
            : (risk == 'medium' ? 'same-day clinic' : 'home care'),
        "action_required": risk != 'low',
        "treatment_suggestions": <String>[],
      },
      "confidence_score": risk == 'high'
          ? 0.8
          : risk == 'medium'
              ? 0.6
              : 0.4,
    };
  }

  Map<String, dynamic> _normalizeStructured(Map<String, dynamic>? raw) {
    final m = (raw ?? const {});
    final ai = (m['ai_insights'] is Map) ? (m['ai_insights'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    return {
      'predicted_symptom': (m['predicted_symptom'] ?? 'unknown').toString(),
      'risk_level': _asRisk(m['risk_level']),
      'ai_insights': {
        'symptom_insight': (ai['symptom_insight'] ?? '').toString(),
        'urgency': (ai['urgency'] ?? 'home care').toString(),
        'action_required': ai['action_required'] == true,
        'treatment_suggestions': (ai['treatment_suggestions'] is List)
            ? List<String>.from(ai['treatment_suggestions'])
            : <String>[],
      },
      'confidence_score': _as0to1(m['confidence_score']),
    };
  }

  String _asRisk(dynamic v) {
    final s = (v ?? '').toString().toLowerCase();
    if (s == 'high' || s == 'medium' || s == 'low') return s;
    return 'medium';
  }

  double _as0to1(dynamic v) {
    final n = (v is num) ? v.toDouble() : 0.0;
    if (n < 0) return 0.0;
    if (n > 1) return 1.0;
    return n;
  }

  // ----------- Fallback content -----------

  String generateFallbackResponse(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('fever')) {
      return 'For fever in children:\n• Monitor temperature every 4–6 hours\n• Keep child hydrated\n• Use acetaminophen or ibuprofen as directed\n• Contact doctor if fever >104°F or lasts >3 days\n\n⚠️ Always consult your pediatrician for personalized advice.';
    } else if (p.contains('cough')) {
      return 'For cough in children:\n• Ensure adequate hydration\n• Honey for children >1 year\n• Consider humidifier\n• Contact doctor if severe or persistent\n\n⚠️ Always consult your pediatrician for personalized advice.';
    } else if (p.contains('vomit')) {
      return 'For vomiting:\n• Small sips of clear fluids\n• Slowly increase intake\n• Watch for dehydration\n• Contact doctor if >24 hours\n\n⚠️ Always consult your pediatrician for personalized advice.';
    } else if (p.contains('diarrhea')) {
      return 'For diarrhea:\n• Oral rehydration solutions\n• Continue normal diet if tolerated\n• Watch for dehydration\n• Contact doctor if severe or bloody\n\n⚠️ Always consult your pediatrician for personalized advice.';
    }
    return 'Monitor the child closely, keep a symptom diary, and contact your pediatrician if symptoms worsen. Seek immediate care for severe symptoms.\n\n⚠️ Always consult your pediatrician for personalized advice.';
  }

  // ----------- Analytics / summaries -----------

  Map<String, double> getQualityScores() => Map.from(_qualityScores);

  void resetQualityScores() {
    _qualityScores['openai'] = 0.0;
    _qualityScores['grok'] = 0.0;
  }

  Future<Map<String, dynamic>> getAnalyticsSummary() =>
      _loggingService.getAnalyticsSummary();

  Map<String, dynamic> getModelPerformanceSummary() =>
      _selector.getPerformanceSummary();

  Map<String, dynamic> getModelRecommendation() =>
      _selector.getRecommendationWithConfidence();

  Future<void> resetModelStats() => _selector.resetStats();

  // ----------- Utils -----------

  String _name(AIModelType t) => t == AIModelType.openai ? 'openai' : 'grok';
}