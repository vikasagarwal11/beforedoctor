import 'dart:convert';
import 'package:http/http.dart' as http;
import 'usage_logger_service.dart';

class SheetUploaderService {
  final UsageLoggerService _loggerService;
  final String _spreadsheetId;
  final String _sheetName;
  final String _serviceAccountEmail;
  final String _accessToken;

  SheetUploaderService({
    required UsageLoggerService loggerService,
    required String spreadsheetId,
    required String sheetName,
    required String serviceAccountEmail,
    required String accessToken,
  })  : _loggerService = loggerService,
        _spreadsheetId = spreadsheetId,
        _sheetName = sheetName,
        _serviceAccountEmail = serviceAccountEmail,
        _accessToken = accessToken;

  Future<bool> uploadLogs() async {
    try {
      final logs = await _loggerService.getUnuploadedLogs();
      if (logs.isEmpty) {
        print('📝 No new logs to upload');
        return true;
      }

      final List<List<Object>> rows = [];

      // Add header row if sheet is empty
      rows.add([
        'Timestamp',
        'Symptom',
        'Prompt Used',
        'Model Used',
        'AI Response',
        'Latency (ms)',
        'Success',
        'Score',
        'Interaction Type',
        'Child Age',
        'Child Gender',
        'Voice Confidence',
        'Error Message',
      ]);

      for (final log in logs) {
        rows.add([
          log['timestamp'] ?? '',
          log['symptom'] ?? '',
          log['prompt_used'] ?? '',
          log['model_used'] ?? '',
          log['ai_response'] ?? '',
          log['latency_ms'] ?? 0,
          log['success'] == 1 ? 'Yes' : 'No',
          log['score'] ?? 0.0,
          log['interaction_type'] ?? '',
          log['child_age'] ?? '',
          log['child_gender'] ?? '',
          log['voice_confidence'] ?? 0.0,
          log['error_message'] ?? '',
        ]);
      }

      final url =
          'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/$_sheetName:append?valueInputOption=USER_ENTERED';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          'values': rows,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully uploaded ${logs.length} logs to Google Sheet');
        // Mark logs as uploaded
        final logIds = logs.map((log) => log['id'] as int).toList();
        await _loggerService.markLogsAsUploaded(logIds);
        return true;
      } else {
        print('❌ Failed to upload logs: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error uploading logs: $e');
      return false;
    }
  }

  Future<bool> uploadLogsByDateRange(DateTime start, DateTime end) async {
    try {
      final logs = await _loggerService.getLogsByDateRange(start, end);
      if (logs.isEmpty) {
        print('📝 No logs found for the specified date range');
        return true;
      }

      final List<List<Object>> rows = [];

      // Add header row
      rows.add([
        'Timestamp',
        'Symptom',
        'Prompt Used',
        'Model Used',
        'AI Response',
        'Latency (ms)',
        'Success',
        'Score',
        'Interaction Type',
        'Child Age',
        'Child Gender',
        'Voice Confidence',
        'Error Message',
      ]);

      for (final log in logs) {
        rows.add([
          log['timestamp'] ?? '',
          log['symptom'] ?? '',
          log['prompt_used'] ?? '',
          log['model_used'] ?? '',
          log['ai_response'] ?? '',
          log['latency_ms'] ?? 0,
          log['success'] == 1 ? 'Yes' : 'No',
          log['score'] ?? 0.0,
          log['interaction_type'] ?? '',
          log['child_age'] ?? '',
          log['child_gender'] ?? '',
          log['voice_confidence'] ?? 0.0,
          log['error_message'] ?? '',
        ]);
      }

      final url =
          'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/$_sheetName:append?valueInputOption=USER_ENTERED';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          'values': rows,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully uploaded ${logs.length} logs for date range to Google Sheet');
        return true;
      } else {
        print('❌ Failed to upload logs: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error uploading logs: $e');
      return false;
    }
  }

  Future<bool> uploadAnalytics() async {
    try {
      final analytics = await _loggerService.getAnalytics();
      
      final List<List<Object>> rows = [
        ['Analytics Report', ''],
        ['Generated At', DateTime.now().toIso8601String()],
        [''],
        ['Metric', 'Value'],
        ['Total Interactions', analytics['total_interactions']],
        ['Successful Interactions', analytics['successful_interactions']],
        ['Failed Interactions', analytics['failed_interactions']],
        ['Success Rate (%)', analytics['success_rate'].toStringAsFixed(2)],
        ['Average Latency (ms)', analytics['average_latency_ms'].toStringAsFixed(0)],
        ['Average Score', analytics['average_score'].toStringAsFixed(3)],
        ['Last Interaction', analytics['last_interaction'] ?? 'N/A'],
        [''],
        ['Model Usage', ''],
      ];

      // Add model usage statistics
      final modelUsage = analytics['model_usage'] as Map<String, int>;
      for (final entry in modelUsage.entries) {
        rows.add([entry.key, entry.value]);
      }

      final url =
          'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/${_sheetName}_Analytics:append?valueInputOption=USER_ENTERED';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          'values': rows,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully uploaded analytics to Google Sheet');
        return true;
      } else {
        print('❌ Failed to upload analytics: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error uploading analytics: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      final url = 'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Google Sheets connection successful');
        return true;
      } else {
        print('❌ Google Sheets connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error testing Google Sheets connection: $e');
      return false;
    }
  }
} 