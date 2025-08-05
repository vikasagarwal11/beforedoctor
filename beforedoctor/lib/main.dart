import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/app_config.dart';
import 'features/voice/presentation/screens/voice_logging_screen.dart';
import 'features/voice/presentation/screens/voice_logger_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  runApp(const ProviderScope(child: BeforeDoctorApp()));
}

class BeforeDoctorApp extends ConsumerWidget {
  const BeforeDoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BeforeDoctor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize app configuration
      final config = AppConfig.instance;
      print('✅ App initialized with configuration: ${config.appName} v${config.appVersion}');
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error initializing app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing BeforeDoctor...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('🏥 BeforeDoctor'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.medical_services,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to BeforeDoctor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI-powered pediatric symptom assistant',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Features Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                                 _buildFeatureCard(
                   icon: Icons.mic,
                   title: 'Voice Logging',
                   subtitle: 'Record symptoms with voice',
                   color: Colors.blue,
                   onTap: () => _navigateToVoiceLogging(),
                 ),
                 _buildFeatureCard(
                   icon: Icons.psychology,
                   title: 'Voice Logger',
                   subtitle: 'Simple voice logger with AI',
                   color: Colors.purple,
                   onTap: () => _navigateToVoiceLogger(),
                 ),
                _buildFeatureCard(
                  icon: Icons.psychology,
                  title: 'AI Analysis',
                  subtitle: 'Smart symptom detection',
                  color: Colors.green,
                  onTap: () => _showFeatureComingSoon('AI Analysis'),
                ),
                _buildFeatureCard(
                  icon: Icons.medical_information,
                  title: 'Treatment Guide',
                  subtitle: 'Age-appropriate advice',
                  color: Colors.orange,
                  onTap: () => _showFeatureComingSoon('Treatment Guide'),
                ),
                _buildFeatureCard(
                  icon: Icons.person,
                  title: 'Character Chat',
                  subtitle: 'Interactive doctor avatar',
                  color: Colors.purple,
                  onTap: () => _showFeatureComingSoon('Character Chat'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Start Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚀 Quick Start',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Start by recording your child\'s symptoms using voice input. Our AI will analyze the symptoms and provide age-appropriate guidance.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToVoiceLogging(),
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Voice Logging'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatusItem('Voice APIs', 'Connected', Colors.green),
                  _buildStatusItem('AI Services', 'Ready', Colors.green),
                  _buildStatusItem('Character Engine', 'Active', Colors.green),
                  _buildStatusItem('Database', 'Local', Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToVoiceLogging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceLoggingScreen(),
      ),
    );
  }

  void _navigateToVoiceLogger() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceLoggerScreen(),
      ),
    );
  }

  void _showFeatureComingSoon(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$featureName Coming Soon'),
        content: Text('This feature is currently under development and will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
