import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:logger/logger.dart';

/// Unified AI results panel:
/// - Preserves your original features (predicted_symptom, risk, insights, confidence).
/// - Adds optional sections for raw LLM text (aiResponse) and diseasePrediction map.
/// - Backward compatible: existing calls that only pass aiResults still work.
class AIResultsWidget extends StatelessWidget {
  /// Existing payload you already use everywhere
  final Map<String, dynamic> aiResults;

  /// Optional: raw LLM output text (if you want to show a narrative)
  final String? aiResponse;

  /// Optional: disease prediction payload (if available from another service)
  final Map<String, dynamic>? diseasePrediction;

  final VoidCallback? onTreatmentTap;
  final VoidCallback? onRiskTap;

  const AIResultsWidget({
    super.key,
    required this.aiResults,
    this.aiResponse,
    this.diseasePrediction,
    this.onTreatmentTap,
    this.onRiskTap,
  });

  @override
  Widget build(BuildContext context) {
    final logger = Logger();

    // If nothing meaningful to show, collapse.
    final hasAnything = (aiResults.isNotEmpty) ||
        ((aiResponse ?? '').trim().isNotEmpty) ||
        ((diseasePrediction ?? {}).isNotEmpty);
    if (!hasAnything) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),

          // Optional: Raw AI response text block
          if ((aiResponse ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAIResponseText(context, aiResponse!.trim()),
          ],

          const SizedBox(height: 12),
          _buildSymptomPrediction(context),
          const SizedBox(height: 12),
          _buildRiskAssessment(context),
          const SizedBox(height: 12),
          _buildAIInsights(context),
          const SizedBox(height: 12),
          _buildConfidenceIndicator(context),

          // Optional: disease prediction block
          if ((diseasePrediction ?? {}).isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDiseasePrediction(context, diseasePrediction!),
          ],
        ],
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.psychology,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'AI Analysis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'AI Enhanced',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ===== (NEW) Raw AI narrative text =====
  Widget _buildAIResponseText(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat, color: Colors.indigo[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Response',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ===== Predicted Symptom =====
  Widget _buildSymptomPrediction(BuildContext context) {
    final symptom = (aiResults['predicted_symptom'] ?? 'unknown').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Predicted Symptom',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            symptom.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Risk Assessment =====
  Widget _buildRiskAssessment(BuildContext context) {
    final riskLevel = (aiResults['risk_level'] ?? 'medium').toString();
    Color riskColor;
    IconData riskIcon;

    switch (riskLevel.toLowerCase()) {
      case 'high':
        riskColor = Colors.red;
        riskIcon = Icons.warning;
        break;
      case 'medium':
        riskColor = Colors.orange;
        riskIcon = Icons.info;
        break;
      case 'low':
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
        break;
      default:
        riskColor = Colors.grey;
        riskIcon = Icons.help;
    }

    return GestureDetector(
      onTap: onRiskTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: riskColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: riskColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(riskIcon, color: riskColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Risk Assessment',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: riskColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                riskLevel.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== AI Insights =====
  Widget _buildAIInsights(BuildContext context) {
    final insights = aiResults['ai_insights'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (insights['symptom_insight'] != null)
            Text(
              insights['symptom_insight'].toString(),
              style: const TextStyle(fontSize: 14),
            ),
          if (insights['urgency'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (insights['action_required'] == true)
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                insights['urgency'].toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: (insights['action_required'] == true)
                      ? Colors.red[700]
                      : Colors.blue[700],
                ),
              ),
            ),
          ],
          if (insights['treatment_suggestions'] != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onTreatmentTap,
              child: Row(
                children: [
                  Icon(Icons.medication, color: Colors.teal[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'View treatment suggestions',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ===== Confidence indicator =====
  Widget _buildConfidenceIndicator(BuildContext context) {
    final confidence = (aiResults['confidence_score'] ?? 0.0) as num;
    final clamped = confidence.clamp(0, 1).toDouble();
    final confidencePercentage = (clamped * 100).round();

    Color barColor;
    if (clamped > 0.7) {
      barColor = Colors.green;
    } else if (clamped > 0.5) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'AI Confidence',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              '$confidencePercentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: clamped,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ],
    );
  }

  // ===== (NEW) Disease prediction panel =====
  Widget _buildDiseasePrediction(
    BuildContext context,
    Map<String, dynamic> dp,
  ) {
    final disease = dp['disease']?.toString() ?? 'Unknown';
    final conf = (dp['confidence'] is num) ? (dp['confidence'] as num).toDouble() : null;
    final similar = (dp['similar'] as List?)?.cast<String>() ?? const <String>[];
    final meds = (dp['medications'] as List?)?.cast<String>() ?? const <String>[];
    final tx = (dp['treatments'] as List?)?.cast<String>() ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Disease Prediction',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Predicted: $disease', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (conf != null) Text('Confidence: ${(conf * 100).toStringAsFixed(1)}%'),
          if (similar.isNotEmpty) Text('Similar: ${similar.take(3).join(', ')}'),
          if (tx.isNotEmpty) Text('Treatments: ${tx.take(3).join(', ')}'),
          if (meds.isNotEmpty) Text('Medications: ${meds.take(2).join(', ')}'),
        ],
      ),
    );
  }
}
