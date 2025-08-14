import 'package:flutter/material.dart';
import '../widgets/child_profile_widget.dart';
import '../widgets/symptom_input_widget.dart';
import '../widgets/model_selection_widget.dart';
import '../widgets/usage_analytics_widget.dart';
import '../widgets/ai_results_widget.dart';
import '../widgets/voice_confidence_widget.dart';

class VoiceLoggerScreen extends StatefulWidget {
  const VoiceLoggerScreen({Key? key}) : super(key: key);

  @override
  State<VoiceLoggerScreen> createState() => _VoiceLoggerScreenState();
}

class _VoiceLoggerScreenState extends State<VoiceLoggerScreen> {
  // Child profile
  Map<String, String> _childMetadata = {
    'child_name': 'Vihaan',
    'child_age': '4',
    'child_gender': 'male',
  };

  // Model selection
  String _selectedModel = 'auto';

  // STT state
  bool _isListening = false;
  String _interimTranscript = '';
  String _finalTranscript = '';
  double _voiceConfidence = 0.0;

  // AI outputs
  String _aiResponse = '';
  Map<String, dynamic> _aiResults = {};          // <— NEW: structured analysis map
  Map<String, dynamic> _diseasePrediction = {};

  // Analytics
  Map<String, dynamic> _analytics = {};

  // ======== Child profile ========
  void _updateChildProfile(Map<String, String> updated) {
    setState(() => _childMetadata = updated);
  }

  // ======== Mic/STT (placeholder wiring) ========
  void _onMicTap() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _interimTranscript = '';
      _aiResponse = '';
      _aiResults = {};
      _finalTranscript = '';
      _voiceConfidence = 0.0;
    });

    // TODO: Replace this block with your actual STT service callbacks
    // Simulate interim updates then "final"
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_isListening) return;
      setState(() => _interimTranscript = 'My 3-year-old has a fever of');
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!_isListening) return;
      setState(() => _interimTranscript = 'My 3-year-old has a fever of 102');
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!_isListening) return;
      setState(() => _interimTranscript = 'My 3-year-old has a fever of 102 for 2 days');
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!_isListening) return;
      // Finalize
      _stopListening(finalText: 'My 3-year-old has a fever of 102 for 2 days', confidence: 0.95);
    });
  }

  void _stopListening({String? finalText, double? confidence}) {
    setState(() {
      _isListening = false;
      if (finalText != null) {
        _finalTranscript = finalText;
        _interimTranscript = finalText;
      }
      if (confidence != null) _voiceConfidence = confidence;
    });
  }

  // ======== Process symptom end-to-end ========
  Future<void> _processSymptom(String symptom) async {
    final query = symptom.trim().isNotEmpty ? symptom.trim() : _finalTranscript.trim();
    if (query.isEmpty) return;

    setState(() {
      _aiResponse = '';
      _aiResults = {};
      _diseasePrediction = {};
    });

    // 1) Call LLM (fallback if Grok 404s)
    String llmText = '';
    try {
      if (_selectedModel == 'grok' || _selectedModel == 'auto') {
        llmText = await _callGrokOrThrow(query);
      }
    } catch (_) {
      // ignore and fallback
    }
    if (llmText.isEmpty && (_selectedModel == 'openai' || _selectedModel == 'auto')) {
      llmText = await _callOpenAI(query);
    }
    if (llmText.isEmpty) {
      llmText = 'I could not generate an answer right now. Please try again.';
    }

    // 2) Structure the results (until your LLM returns JSON)
    final structured = _structureAI(llmText, query, _childMetadata);

    // 3) (Optional) Disease prediction stub – replace with your service
    final disease = _mockDiseasePrediction(query);

    // 4) Update UI
    setState(() {
      _aiResponse = llmText;
      _aiResults = structured;
      _diseasePrediction = disease;
    });
  }

  // ======== LLM calls (replace with your services) ========
  Future<String> _callGrokOrThrow(String prompt) async {
    // TODO: call your real Grok client; 404 means path or model mismatch
    // Simulate a 404 sometimes:
    throw Exception('Grok 404');
  }

  Future<String> _callOpenAI(String prompt) async {
    // TODO: call your real OpenAI client
    await Future.delayed(const Duration(milliseconds: 400));
    return '''
Based on the child's history, fever of 102°F for 2 days is most likely viral. Ensure hydration, use acetaminophen at weight-based dosing, and monitor for red flags (trouble breathing, stiff neck, persistent vomiting, dehydration). If fever persists beyond 72 hours or symptoms worsen, seek medical evaluation.
''';
  }

  // ======== Structuring layer (make JSON from text locally for now) ========
  Map<String, dynamic> _structureAI(String aiText, String userQuery, Map<String, String> child) {
    // Simple heuristic example — replace with model JSON later
    final lower = '$aiText $userQuery'.toLowerCase();
    final predictedSymptom = lower.contains('fever') ? 'fever'
        : lower.contains('cough') ? 'cough'
        : lower.contains('vomit') ? 'vomiting'
        : 'unspecified';

    String risk = 'medium';
    if (lower.contains('trouble breathing') || lower.contains('stiff neck') || lower.contains('dehydration')) {
      risk = 'high';
    } else if (lower.contains('mild') || lower.contains('self care')) {
      risk = 'low';
    }

    final insights = <String, dynamic>{
      'symptom_insight': 'Likely viral illness given short duration and isolated fever.',
      'urgency': risk == 'high' ? 'Urgent evaluation recommended' : risk == 'medium' ? 'Monitor at home; follow-up if worse' : 'Self-care likely sufficient',
      'action_required': risk == 'high',
      'treatment_suggestions': [
        'Acetaminophen based on weight',
        'Fluids / hydration',
        'Rest',
      ],
    };

    // Confidence can be blended from model + STT + rules — here a simple blend:
    final sttBoost = (_voiceConfidence.clamp(0.0, 1.0)) * 0.2;
    final base = risk == 'high' ? 0.75 : risk == 'medium' ? 0.65 : 0.55;
    final confidence = (base + sttBoost).clamp(0.0, 1.0);

    return {
      'predicted_symptom': predictedSymptom,
      'risk_level': risk,
      'ai_insights': insights,
      'confidence_score': confidence,
    };
  }

  Map<String, dynamic> _mockDiseasePrediction(String userQuery) {
    // Replace with your DiseasePredictionService
    if (userQuery.toLowerCase().contains('fever')) {
      return {
        'disease': 'Viral upper respiratory infection',
        'confidence': 0.82,
        'similar': ['Influenza', 'Common cold', 'RSV'],
        'treatments': ['Fluids', 'Rest', 'Antipyretics'],
        'medications': ['Acetaminophen', 'Ibuprofen (age/weight appropriate)'],
      };
    }
    return {};
  }

  // ======== Model selection / analytics ========
  void _onModelChanged(String model) {
    setState(() => _selectedModel = model);
  }

  void _clearAnalytics() {
    setState(() => _analytics = {});
  }

  // ======== UI ========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BeforeDoctor: Voice Assistant")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ChildProfileWidget(
            childMetadata: _childMetadata,
            onUpdate: _updateChildProfile,
          ),
          const SizedBox(height: 16),

          // Mic-aware input
          SymptomInputWidget(
            onSymptomEntered: _processSymptom,
            isListening: _isListening,
            interimTranscript: _interimTranscript,
            onMicTap: _onMicTap,
          ),

          const SizedBox(height: 16),
          // Show confidence + Accept/Re-record after STT finalizes
          if (!_isListening && _finalTranscript.isNotEmpty) ...[
            VoiceConfidenceWidget(
              confidenceScore: _voiceConfidence,
              transcription: _finalTranscript,
              onReRecord: _startListening,
              onAccept: () => _processSymptom(_finalTranscript),
            ),
            const SizedBox(height: 16),
          ],

          ModelSelectionWidget(
            selectedModel: _selectedModel,
            onModelChanged: _onModelChanged,
          ),
          const SizedBox(height: 16),

          UsageAnalyticsWidget(
            analytics: _analytics,
            onClear: _clearAnalytics,
          ),
          const SizedBox(height: 16),

          // The AI panel now has all three: structured map, raw text, disease prediction
          AIResultsWidget(
            aiResults: _aiResults,             // <— now real data
            aiResponse: _aiResponse,
            diseasePrediction: _diseasePrediction,
          ),
        ],
      ),
    );
  }
}
