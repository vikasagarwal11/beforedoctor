import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:logger/logger.dart';

class AIResultsWidget extends StatelessWidget {
  final Map<String, dynamic> aiResults;
  final VoidCallback? onTreatmentTap;
  final VoidCallback? onRiskTap;
  
  const AIResultsWidget({
    super.key,
    required this.aiResults,
    this.onTreatmentTap,
    this.onRiskTap,
  });

  @override
  Widget build(BuildContext context) {
    final logger = Logger();
    
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
          const SizedBox(height: 12),
          _buildSymptomPrediction(context),
          const SizedBox(height: 12),
          _buildRiskAssessment(context),
          const SizedBox(height: 12),
          _buildAIInsights(context),
          const SizedBox(height: 12),
          _buildConfidenceIndicator(context),
        ],
      ),
    );
  }
  
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
  
  Widget _buildSymptomPrediction(BuildContext context) {
    final symptom = aiResults['predicted_symptom'] ?? 'unknown';
    
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
  
  Widget _buildRiskAssessment(BuildContext context) {
    final riskLevel = aiResults['risk_level'] ?? 'medium';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
          ],
        ),
      ),
    );
  }
  
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
              insights['symptom_insight'],
              style: const TextStyle(fontSize: 14),
            ),
          if (insights['urgency'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: insights['action_required'] == true 
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                insights['urgency'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: insights['action_required'] == true 
                      ? Colors.red[700]
                      : Colors.blue[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildConfidenceIndicator(BuildContext context) {
    final confidence = aiResults['confidence_score'] ?? 0.0;
    final confidencePercentage = (confidence * 100).round();
    
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
                color: confidence > 0.7 ? Colors.green : 
                       confidence > 0.5 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: confidence,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            confidence > 0.7 ? Colors.green : 
            confidence > 0.5 ? Colors.orange : Colors.red,
          ),
        ),
      ],
    );
  }
} 