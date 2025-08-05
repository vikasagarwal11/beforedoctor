// Filename: lib/screens/voice_logger_screen.dart

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/ai_prompt_service.dart';

class VoiceLoggerScreen extends StatefulWidget {
  const VoiceLoggerScreen({Key? key}) : super(key: key);

  @override
  _VoiceLoggerScreenState createState() => _VoiceLoggerScreenState();
}

class _VoiceLoggerScreenState extends State<VoiceLoggerScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = '';
  final AIPromptService _promptService = AIPromptService();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _promptService.loadTemplates();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _transcription = val.recognizedWords;
        });
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processTranscription() {
    // Extract symptom (basic mock for now)
    final matchedSymptom = _promptService.getSupportedSymptoms().firstWhere(
      (s) => _transcription.toLowerCase().contains(s),
      orElse: () => '',
    );

    if (matchedSymptom.isNotEmpty) {
      final prompt = _promptService.buildLLMPrompt(matchedSymptom, {
        'child_age': '4',
        'gender': 'female',
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Prompt for $matchedSymptom'),
          content: Text(prompt),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching symptom found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Logger')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
            const SizedBox(height: 20),
            Text(_transcription.isEmpty ? 'Say something...' : _transcription),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _processTranscription,
              child: const Text('Process Transcription'),
            )
          ],
        ),
      ),
    );
  }
}
