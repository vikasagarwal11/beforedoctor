import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'sheet_uploader_service.dart';
import 'usage_logger_service.dart';

// Example of how to use SheetUploaderService
class SheetUploaderExample {
  static Future<void> setupAndUpload() async {
    // Initialize the usage logger
    final usageLogger = UsageLoggerService();
    await usageLogger.init();

    // Get credentials from environment variables
    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'] ?? '';
    final sheetName = dotenv.env['GOOGLE_SHEET_NAME'] ?? 'Logs';
    final serviceAccountEmail = dotenv.env['GOOGLE_SERVICE_ACCOUNT_EMAIL'] ?? '';
    final accessToken = dotenv.env['GOOGLE_ACCESS_TOKEN'] ?? '';

    if (spreadsheetId.isEmpty || serviceAccountEmail.isEmpty || accessToken.isEmpty) {
      print('❌ Missing Google Sheets configuration. Please check your .env file.');
      return;
    }

    // Create the sheet uploader service
    final sheetUploader = SheetUploaderService(
      loggerService: usageLogger,
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
      serviceAccountEmail: serviceAccountEmail,
      accessToken: accessToken,
    );

    // Test the connection first
    final connectionTest = await sheetUploader.testConnection();
    if (!connectionTest) {
      print('❌ Failed to connect to Google Sheets. Please check your credentials.');
      return;
    }

    // Upload all logs
    final uploadSuccess = await sheetUploader.uploadLogs();
    if (uploadSuccess) {
      print('✅ Successfully uploaded logs to Google Sheets');
    } else {
      print('❌ Failed to upload logs to Google Sheets');
    }

    // Upload analytics
    final analyticsSuccess = await sheetUploader.uploadAnalytics();
    if (analyticsSuccess) {
      print('✅ Successfully uploaded analytics to Google Sheets');
    } else {
      print('❌ Failed to upload analytics to Google Sheets');
    }
  }

  static Future<void> uploadByDateRange(DateTime start, DateTime end) async {
    final usageLogger = UsageLoggerService();
    await usageLogger.init();

    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'] ?? '';
    final sheetName = dotenv.env['GOOGLE_SHEET_NAME'] ?? 'Logs';
    final serviceAccountEmail = dotenv.env['GOOGLE_SERVICE_ACCOUNT_EMAIL'] ?? '';
    final accessToken = dotenv.env['GOOGLE_ACCESS_TOKEN'] ?? '';

    if (spreadsheetId.isEmpty || serviceAccountEmail.isEmpty || accessToken.isEmpty) {
      print('❌ Missing Google Sheets configuration.');
      return;
    }

    final sheetUploader = SheetUploaderService(
      loggerService: usageLogger,
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
      serviceAccountEmail: serviceAccountEmail,
      accessToken: accessToken,
    );

    final success = await sheetUploader.uploadLogsByDateRange(start, end);
    if (success) {
      print('✅ Successfully uploaded logs for date range to Google Sheets');
    } else {
      print('❌ Failed to upload logs for date range to Google Sheets');
    }
  }
}

// Example .env file configuration:
/*
GOOGLE_SHEET_ID=your_spreadsheet_id_here
GOOGLE_SHEET_NAME=Logs
GOOGLE_SERVICE_ACCOUNT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
GOOGLE_ACCESS_TOKEN=your_access_token_here
*/

// Usage in your app:
/*
// Upload all logs
await SheetUploaderExample.setupAndUpload();

// Upload logs for a specific date range
final startDate = DateTime.now().subtract(Duration(days: 7));
final endDate = DateTime.now();
await SheetUploaderExample.uploadByDateRange(startDate, endDate);
*/ 