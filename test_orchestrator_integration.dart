import 'package:flutter/material.dart';
import 'package:beforedoctor/core/services/ai_response_orchestrator.dart';

void main() {
  runApp(OrchestratorTestApp());
}

class OrchestratorTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orchestrator Test',
      home: OrchestratorTestScreen(),
    );
  }
}

class OrchestratorTestScreen extends StatefulWidget {
  @override
  _OrchestratorTestScreenState createState() => _OrchestratorTestScreenState();
}

class _OrchestratorTestScreenState extends State<OrchestratorTestScreen> {
  final AIResponseOrchestrator _orchestrator = AIResponseOrchestrator();
  String _testResult = '';
  bool _isTesting = false;

  Future<void> _testOrchestrator() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing...';
    });

    try {
      final childContext = {
        'child_age': 4,
        'has_chronic_condition': false,
        'recent_illness': false,
        'immunization_status': 'complete',
      };

      final response = await _orchestrator.getComprehensiveResponse(
        symptoms: ['fever', 'cough'],
        childContext: childContext,
        userQuestion: 'What should I do for my child?',
      );

      setState(() {
        _testResult = '''
✅ Test Successful!

Response: ${response['response']}
Risk Level: ${response['risk_level']}
Risk Score: ${response['risk_score']}
Recommendations: ${response['recommendations']?.join(', ')}
Data Sources: ${response['data_sources']}
Confidence: ${response['confidence']}
Type: ${response['type']}
''';
        _isTesting = false;
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ Test Failed: $e';
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Orchestrator Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _testOrchestrator,
              child: Text(_isTesting ? 'Testing...' : 'Test Orchestrator'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _testResult,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 