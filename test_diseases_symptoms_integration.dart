import 'package:flutter/material.dart';
import 'beforedoctor/lib/services/diseases_symptoms_service.dart';

void main() {
  runApp(DiseasesSymptomsTestApp());
}

class DiseasesSymptomsTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diseases_Symptoms Integration Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DiseasesSymptomsTestScreen(),
    );
  }
}

class DiseasesSymptomsTestScreen extends StatefulWidget {
  @override
  _DiseasesSymptomsTestScreenState createState() => _DiseasesSymptomsTestScreenState();
}

class _DiseasesSymptomsTestScreenState extends State<DiseasesSymptomsTestScreen> {
  final DiseasesSymptomsService _diseasesService = DiseasesSymptomsService();
  final TextEditingController _symptomController = TextEditingController();
  Map<String, dynamic>? _analysisResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _diseasesService.initialize();
      print('✅ Diseases_Symptoms service initialized successfully');
    } catch (e) {
      print('❌ Error initializing service: $e');
    }
  }

  Future<void> _testAnalysis() async {
    if (_symptomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter symptoms to test')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    try {
      final result = await _diseasesService.analyzeSymptoms(_symptomController.text);
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏥 AI Disease Analysis Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('Symptoms: ${(_analysisResult!['symptoms'] as List).join(', ')}'),
          SizedBox(height: 8),
          Text('Urgency Level: ${_analysisResult!['urgency_level'].toString().toUpperCase()}'),
          if ((_analysisResult!['emergency_symptoms'] as List).isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              '⚠️ Emergency Symptoms: ${(_analysisResult!['emergency_symptoms'] as List).join(', ')}',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
          if (_analysisResult!['recommendations']['treatment'] != null) ...[
            SizedBox(height: 8),
            Text('Treatment: ${_analysisResult!['recommendations']['treatment']['treatment']}'),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diseases_Symptoms Integration Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Test Diseases_Symptoms Integration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _symptomController,
              decoration: InputDecoration(
                labelText: 'Enter symptoms to test',
                hintText: 'e.g., fever, cough, headache',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAnalysis,
              child: _isLoading 
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Analyze Symptoms'),
            ),
            SizedBox(height: 20),
            Expanded(child: _buildAnalysisResult()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _diseasesService.dispose();
    super.dispose();
  }
} 