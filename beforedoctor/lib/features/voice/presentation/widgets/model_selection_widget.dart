import 'package:flutter/material.dart';

class ModelSelectionWidget extends StatelessWidget {
  final String selectedModel;
  final void Function(String) onModelChanged;

  const ModelSelectionWidget({
    required this.selectedModel,
    required this.onModelChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Text("AI Model:"),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: selectedModel,
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('Auto')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                DropdownMenuItem(value: 'grok', child: Text('Grok')),
              ],
              onChanged: (v) {
    if (v != null) onModelChanged(v);
  },
            ),
          ],
        ),
      ),
    );
  }
}
