import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/getwidget.dart';
import '../../../../core/providers/config_provider.dart';

class VoiceApiSettingsScreen extends ConsumerStatefulWidget {
  const VoiceApiSettingsScreen({super.key});

  @override
  ConsumerState<VoiceApiSettingsScreen> createState() => _VoiceApiSettingsScreenState();
}

class _VoiceApiSettingsScreenState extends ConsumerState<VoiceApiSettingsScreen> {
  String? selectedPrimaryApi;
  String? selectedFallbackApi;
  bool autoFallbackEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(voiceApiSettingsProvider);
      selectedPrimaryApi = settings.primaryApi;
      selectedFallbackApi = settings.fallbackApi;
      autoFallbackEnabled = settings.autoFallbackEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(voiceApiSettingsProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice API Settings'),
        backgroundColor: Colors.blue[50],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Status Section
            _buildApiStatusSection(config),
            const SizedBox(height: 24),
            
            // Primary API Selection
            _buildPrimaryApiSection(settings),
            const SizedBox(height: 24),
            
            // Fallback API Selection
            _buildFallbackApiSection(settings),
            const SizedBox(height: 24),
            
            // Auto-fallback Toggle
            _buildAutoFallbackSection(),
            const SizedBox(height: 24),
            
            // Test APIs Button
            _buildTestApisButton(),
            const Spacer(),
            
            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiStatusSection(AppConfig config) {
    return GFListTile(
      title: const Text('API Status', style: TextStyle(fontWeight: FontWeight.bold)),
      subTitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildApiStatusItem('xAI Grok', config.hasGrokApi),
          _buildApiStatusItem('OpenAI', config.hasOpenAIApi),
        ],
      ),
      icon: Icon(Icons.api, color: Colors.blue),
    );
  }

  Widget _buildApiStatusItem(String apiName, bool isAvailable) {
    return Row(
      children: [
        Icon(
          isAvailable ? Icons.check_circle : Icons.error,
          color: isAvailable ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text('$apiName: ${isAvailable ? 'Available' : 'Not configured'}'),
      ],
    );
  }

  Widget _buildPrimaryApiSection(VoiceApiSettings settings) {
    return GFListTile(
      title: const Text('Primary Voice API', style: TextStyle(fontWeight: FontWeight.bold)),
      subTitle: DropdownButton<String>(
        value: selectedPrimaryApi,
        isExpanded: true,
        items: settings.availableApis.map((api) {
          return DropdownMenuItem(
            value: api,
            child: Text(api.toUpperCase()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedPrimaryApi = value;
          });
        },
      ),
      icon: Icon(Icons.mic, color: Colors.blue),
    );
  }

  Widget _buildFallbackApiSection(VoiceApiSettings settings) {
    return GFListTile(
      title: const Text('Fallback Voice API', style: TextStyle(fontWeight: FontWeight.bold)),
      subTitle: DropdownButton<String>(
        value: selectedFallbackApi,
        isExpanded: true,
        items: settings.availableApis.map((api) {
          return DropdownMenuItem(
            value: api,
            child: Text(api.toUpperCase()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedFallbackApi = value;
          });
        },
      ),
      icon: Icon(Icons.backup, color: Colors.orange),
    );
  }

  Widget _buildAutoFallbackSection() {
    return GFListTile(
      title: const Text('Auto-fallback on Errors', style: TextStyle(fontWeight: FontWeight.bold)),
      subTitle: const Text('Automatically switch to fallback API if primary fails'),
      trailing: Switch(
        value: autoFallbackEnabled,
        onChanged: (value) {
          setState(() {
            autoFallbackEnabled = value;
          });
        },
      ),
      icon: Icon(Icons.swap_horiz, color: Colors.green),
    );
  }

  Widget _buildTestApisButton() {
    return SizedBox(
      width: double.infinity,
      child: GFButton(
        onPressed: () {
          // TODO: Implement API testing
          _showTestDialog();
        },
        text: 'Test Voice APIs',
        icon: Icon(Icons.play_arrow),
        color: Colors.blue,
        fullWidthButton: true,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: GFButton(
        onPressed: () {
          // TODO: Save settings to .env or local storage
          _saveSettings();
        },
        text: 'Save Settings',
        icon: Icon(Icons.save),
        color: Colors.green,
        fullWidthButton: true,
      ),
    );
  }

  void _showTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Voice APIs'),
        content: const Text('This will test both voice APIs with a sample voice input.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual API testing
              _testVoiceApis();
            },
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }

  void _testVoiceApis() {
    // TODO: Implement voice API testing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice API testing feature coming soon!')),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to .env or local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved!')),
    );
  }
} 