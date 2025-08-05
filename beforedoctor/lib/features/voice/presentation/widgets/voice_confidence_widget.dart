import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class VoiceConfidenceWidget extends StatelessWidget {
  final double confidenceScore; // 0.0 to 1.0
  final String transcription;
  final VoidCallback onReRecord;
  final VoidCallback onAccept;

  const VoiceConfidenceWidget({
    super.key,
    required this.confidenceScore,
    required this.transcription,
    required this.onReRecord,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final confidencePercentage = (confidenceScore * 100).round();
    final isLowConfidence = confidenceScore < 0.9; // 90% threshold

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLowConfidence ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowConfidence ? Colors.orange : Colors.green,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence Score Header
          Row(
            children: [
              Icon(
                isLowConfidence ? Icons.warning : Icons.check_circle,
                color: isLowConfidence ? Colors.orange : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Clarity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLowConfidence ? Colors.orange[800] : Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Confidence Score Bar
          _buildConfidenceBar(confidencePercentage, isLowConfidence),
          const SizedBox(height: 12),

          // Transcription Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transcription:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transcription.isEmpty ? 'No speech detected' : transcription,
                  style: TextStyle(
                    fontSize: 16,
                    color: transcription.isEmpty ? Colors.grey[500] : Colors.black87,
                    fontStyle: transcription.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GFButton(
                  onPressed: onReRecord,
                  text: 'Re-record',
                  icon: Icon(Icons.mic),
                  color: Colors.orange,
                  fullWidthButton: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GFButton(
                  onPressed: confidenceScore > 0.7 ? onAccept : null, // Disable if very low confidence
                  text: 'Accept',
                  icon: Icon(Icons.check),
                  color: Colors.green,
                  fullWidthButton: true,
                ),
              ),
            ],
          ),

          // Low Confidence Warning
          if (isLowConfidence) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Low confidence detected. Consider re-recording for better accuracy.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(int percentage, bool isLowConfidence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isLowConfidence ? Colors.orange[800] : Colors.green[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isLowConfidence ? Colors.orange : Colors.green,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Poor',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Excellent',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
} 