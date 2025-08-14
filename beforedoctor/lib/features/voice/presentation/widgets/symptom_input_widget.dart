//beforedoctor/lib/features/voice/presentation/widgets/symptom_input_widget.dart
import 'package:flutter/material.dart';

class SymptomInputWidget extends StatefulWidget {
  final void Function(String) onSymptomEntered;

  /// Mic/STT enhancements
  final bool isListening;
  final String interimTranscript;
  final VoidCallback? onMicTap;

  const SymptomInputWidget({
    super.key,
    required this.onSymptomEntered,
    this.isListening = false,
    this.interimTranscript = '',
    this.onMicTap,
  });

  @override
  State<SymptomInputWidget> createState() => _SymptomInputWidgetState();
}

class _SymptomInputWidgetState extends State<SymptomInputWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.interimTranscript);
  }

  @override
  void didUpdateWidget(covariant SymptomInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the text field in sync with interim transcript while listening
    if (widget.isListening && widget.interimTranscript != _controller.text) {
      _controller.text = widget.interimTranscript;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) widget.onSymptomEntered(text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.isListening,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: widget.isListening ? 'Listening…' : 'Enter symptom',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.edit_note),
                      suffixIcon: widget.isListening
                          ? const Icon(Icons.mic, color: Colors.red)
                          : IconButton(
                              icon: const Icon(Icons.mic),
                              onPressed: widget.onMicTap,
                            ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: widget.isListening ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Analyze'),
                ),
              ],
            ),
            if (widget.isListening) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mic, color: Colors.red[600], size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Listening… tap mic to stop', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
