import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class DataManagementService {
  static DataManagementService? _instance;
  static DataManagementService get instance => _instance ??= DataManagementService._internal();

  DataManagementService._internal();

  // File paths
  static const String _templatesPath = 'assets/data/pediatric_llm_prompt_templates_full.json';
  static const String _processedPath = 'assets/data/processed/';
  static const String _backupPath = 'assets/data/backup/';

  // Version tracking
  String _currentVersion = '1.0.0';
  DateTime _lastModified = DateTime.now();

  /// Load templates from assets
  Future<Map<String, dynamic>> loadTemplates() async {
    try {
      final jsonString = await rootBundle.loadString(_templatesPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Update version info
      _lastModified = DateTime.now();
      
      return data;
    } catch (e) {
      print('Error loading templates: $e');
      return {};
    }
  }

  /// Save processed templates to processed folder
  Future<void> saveProcessedTemplates(Map<String, dynamic> templates, String version) async {
    try {
      final processedData = {
        'version': version,
        'processed_date': DateTime.now().toIso8601String(),
        'templates': templates,
        'metadata': {
          'total_symptoms': templates.length,
          'supported_languages': ['en', 'es', 'zh', 'fr', 'hi'],
          'last_updated': DateTime.now().toIso8601String(),
        }
      };

      final fileName = 'pediatric_templates_v$version.json';
      final filePath = path.join(_processedPath, fileName);
      
      // Create processed directory if it doesn't exist
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(filePath);
      await file.writeAsString(jsonEncode(processedData));
      
      print('✅ Processed templates saved to: $filePath');
    } catch (e) {
      print('❌ Error saving processed templates: $e');
    }
  }

  /// Create backup of current templates
  Future<void> createBackup() async {
    try {
      final templates = await loadTemplates();
      final backupData = {
        'backup_date': DateTime.now().toIso8601String(),
        'version': _currentVersion,
        'templates': templates,
      };

      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = path.join(_backupPath, fileName);
      
      // Create backup directory if it doesn't exist
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(filePath);
      await file.writeAsString(jsonEncode(backupData));
      
      print('✅ Backup created: $filePath');
    } catch (e) {
      print('❌ Error creating backup: $e');
    }
  }

  /// Get template statistics
  Map<String, dynamic> getTemplateStats(Map<String, dynamic> templates) {
    final stats = {
      'total_symptoms': templates.length,
      'symptoms': templates.keys.toList(),
      'total_prompts': 0,
      'total_follow_up_questions': 0,
      'total_red_flags': 0,
    };

    templates.forEach((symptom, template) {
      if (template is Map<String, dynamic>) {
        stats['total_prompts']++;
        
        if (template['follow_up_questions'] is List) {
          stats['total_follow_up_questions'] += (template['follow_up_questions'] as List).length;
        }
        
        if (template['red_flags'] is List) {
          stats['total_red_flags'] += (template['red_flags'] as List).length;
        }
      }
    });

    return stats;
  }

  /// Validate template structure
  bool validateTemplateStructure(Map<String, dynamic> templates) {
    final requiredFields = ['prompt_template', 'follow_up_questions'];
    final requiredRedFlags = ['red_flags'];

    for (final symptom in templates.keys) {
      final template = templates[symptom];
      if (template is! Map<String, dynamic>) {
        print('❌ Invalid template structure for symptom: $symptom');
        return false;
      }

      for (final field in requiredFields) {
        if (!template.containsKey(field)) {
          print('❌ Missing required field "$field" for symptom: $symptom');
          return false;
        }
      }

      // Check for red_flags (optional but recommended)
      if (!template.containsKey('red_flags')) {
        print('⚠️ Missing red_flags for symptom: $symptom');
      }
    }

    return true;
  }

  /// Export templates to different formats
  Future<void> exportTemplates(Map<String, dynamic> templates, String format) async {
    try {
      switch (format.toLowerCase()) {
        case 'csv':
          await _exportToCSV(templates);
          break;
        case 'json':
          await _exportToJSON(templates);
          break;
        case 'markdown':
          await _exportToMarkdown(templates);
          break;
        default:
          print('❌ Unsupported export format: $format');
      }
    } catch (e) {
      print('❌ Error exporting templates: $e');
    }
  }

  /// Export to CSV format
  Future<void> _exportToCSV(Map<String, dynamic> templates) async {
    final csvData = StringBuffer();
    csvData.writeln('Symptom,Prompt Template,Follow-up Questions,Red Flags');

    templates.forEach((symptom, template) {
      if (template is Map<String, dynamic>) {
        final prompt = (template['prompt_template'] as String).replaceAll('\n', ' ').replaceAll(',', ';');
        final followUps = (template['follow_up_questions'] as List).join('; ');
        final redFlags = (template['red_flags'] as List?)?.join('; ') ?? '';
        
        csvData.writeln('$symptom,"$prompt","$followUps","$redFlags"');
      }
    });

    final fileName = 'pediatric_templates_${DateTime.now().millisecondsSinceEpoch}.csv';
    final filePath = path.join(_processedPath, fileName);
    
    final file = File(filePath);
    await file.writeAsString(csvData.toString());
    
    print('✅ CSV exported to: $filePath');
  }

  /// Export to JSON format
  Future<void> _exportToJSON(Map<String, dynamic> templates) async {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'version': _currentVersion,
      'templates': templates,
      'stats': getTemplateStats(templates),
    };

    final fileName = 'pediatric_templates_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = path.join(_processedPath, fileName);
    
    final file = File(filePath);
    await file.writeAsString(jsonEncode(exportData));
    
    print('✅ JSON exported to: $filePath');
  }

  /// Export to Markdown format
  Future<void> _exportToMarkdown(Map<String, dynamic> templates) async {
    final markdownData = StringBuffer();
    markdownData.writeln('# Pediatric Symptom Templates');
    markdownData.writeln('');
    markdownData.writeln('**Export Date:** ${DateTime.now().toIso8601String()}');
    markdownData.writeln('**Version:** $_currentVersion');
    markdownData.writeln('**Total Symptoms:** ${templates.length}');
    markdownData.writeln('');

    templates.forEach((symptom, template) {
      if (template is Map<String, dynamic>) {
        markdownData.writeln('## $symptom');
        markdownData.writeln('');
        markdownData.writeln('### Prompt Template');
        markdownData.writeln('```');
        markdownData.writeln(template['prompt_template']);
        markdownData.writeln('```');
        markdownData.writeln('');

        if (template['follow_up_questions'] is List) {
          markdownData.writeln('### Follow-up Questions');
          for (final question in template['follow_up_questions']) {
            markdownData.writeln('- $question');
          }
          markdownData.writeln('');
        }

        if (template['red_flags'] is List) {
          markdownData.writeln('### Red Flags');
          for (final flag in template['red_flags']) {
            markdownData.writeln('- $flag');
          }
          markdownData.writeln('');
        }

        markdownData.writeln('---');
        markdownData.writeln('');
      }
    });

    final fileName = 'pediatric_templates_${DateTime.now().millisecondsSinceEpoch}.md';
    final filePath = path.join(_processedPath, fileName);
    
    final file = File(filePath);
    await file.writeAsString(markdownData.toString());
    
    print('✅ Markdown exported to: $filePath');
  }

  /// Get current version
  String get currentVersion => _currentVersion;

  /// Get last modified date
  DateTime get lastModified => _lastModified;

  /// Update version
  void updateVersion(String newVersion) {
    _currentVersion = newVersion;
    _lastModified = DateTime.now();
  }
}

// Example usage:
// final dataService = DataManagementService.instance;
// final templates = await dataService.loadTemplates();
// await dataService.saveProcessedTemplates(templates, '1.0.0');
// await dataService.exportTemplates(templates, 'csv'); 