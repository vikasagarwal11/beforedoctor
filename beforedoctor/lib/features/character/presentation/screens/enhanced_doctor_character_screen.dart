import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import 'package:getwidget/getwidget.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle; // Added for _debugPrintAssetManifest
import 'package:flutter/foundation.dart' show kDebugMode; // Added for kDebugMode
import '../../../../core/providers/character_state_provider.dart';
import '../../../../core/theme/pediatric_theme.dart';
import '../widgets/mouse_3d_widget.dart';
import '../../services/character_animator.dart';
import '../../../../core/services/performance_monitor_service.dart'; // Performance monitoring

/// Enhanced doctor character screen with Rive animations and lip-sync
class EnhancedDoctorCharacterScreen extends ConsumerStatefulWidget {
  const EnhancedDoctorCharacterScreen({super.key});

  @override
  ConsumerState<EnhancedDoctorCharacterScreen> createState() => _EnhancedDoctorCharacterScreenState();
}

class _EnhancedDoctorCharacterScreenState extends ConsumerState<EnhancedDoctorCharacterScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Rive controller
  RiveAnimationController? _riveController;
  StateMachineController? _stateMachineController;
  
  // 3D Character Animator
  CharacterAnimator? _characterAnimator;
  
  // UI state
  bool _isInitialized = false;
  bool _isTalking = false; // New state for talking control
  
  @override
  void initState() {
    super.initState();
    
    // Start performance monitoring for development
    if (kDebugMode) {
      PerformanceMonitorService.instance.startMonitoring(interval: const Duration(seconds: 10));
    }
    
    _debugPrintAssetManifest(); // Add debug asset manifest check
    _initializeAnimations();
    _initializeCharacterSystem();
    _testAssetLoading(); // Add asset loading test
  }

  /// Debug function to check if 3D models are in the asset manifest
  Future<void> _debugPrintAssetManifest() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      _logger.i('📋 Asset manifest loaded, length: ${manifest.length}');
      
      // Check for 3D models in the new location
      final models = ['mouse.glb', 'hippo.glb', 'jaguar.glb', 'rabbit.glb'];
      var foundCount = 0;
      
      for (final model in models) {
        if (manifest.contains('assets/3d/$model')) {
          _logger.i('✅ $model is in AssetManifest at assets/3d/');
          foundCount++;
        } else {
          _logger.w('⛔ $model NOT in AssetManifest at assets/3d/');
        }
      }
      
      _logger.i('📊 Found $foundCount out of ${models.length} 3D models in assets/3d/');
      
      // Check if 3d folder is referenced
      if (manifest.contains('assets/3d/')) {
        _logger.i('✅ assets/3d/ folder is referenced in manifest');
      } else {
        _logger.w('⛔ assets/3d/ folder NOT found in manifest');
      }
      
    } catch (e) {
      _logger.e('❌ Failed to load AssetManifest: $e');
    }
  }

  @override
  void didUpdateWidget(covariant EnhancedDoctorCharacterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _driveAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _driveAnimation();
  }

  /// Drive 3D animations based on character state
  void _driveAnimation() {
    if (_characterAnimator == null) return;
    
    final characterState = ref.read(characterStateProvider);
    final clip = switch (characterState.currentState) {
      'idle' => 'Idle',
      'listening' => 'Listen',
      'speaking' => 'Speak',
      'thinking' => 'Think',
      'happy' => 'Happy',
      'concerned' => 'Concerned',
      'explaining' => 'Explain',
      _ => 'Idle', // Default fallback
    };
    
    _logger.d('🎭 Driving animation: ${characterState.currentState} → $clip');
    _characterAnimator?.play(clip);
  }

  /// Test asset loading to verify Flutter can access 3D model files
  Future<void> _testAssetLoading() async {
    try {
      _logger.i('🧪 Testing 3D model asset loading...');
      
      // Test all 3D models in the new 3d folder
      final models = ['mouse.glb', 'hippo.glb', 'jaguar.glb', 'rabbit.glb'];
      var successCount = 0;
      
      for (final model in models) {
        try {
          final data = await rootBundle.load('assets/3d/$model');
          _logger.i('✅ Successfully loaded assets/3d/$model: ${data.lengthInBytes} bytes');
          successCount++;
        } catch (e) {
          _logger.w('⚠️ Failed to load assets/3d/$model: $e');
        }
      }
      
      _logger.i('📊 Asset loading test complete: $successCount out of ${models.length} models loaded successfully');
      
    } catch (e) {
      _logger.e('❌ Asset loading test failed: $e');
    }
  }

  void _initializeAnimations() {
    // Fade animation for smooth transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation for character interactions
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _initializeCharacterSystem() async {
    try {
      _logger.i('🎭 Initializing Enhanced Doctor Character Screen');
      
      // Initialize the character state system
      final characterStateNotifier = ref.read(characterStateProvider.notifier);
      await characterStateNotifier.initialize();
      
      // Set initialized state directly
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _fadeController.forward();
        _logger.i('🎭 Character system initialized successfully');
      }
      
    } catch (e) {
      _logger.e('❌ Error initializing character system: $e');
      _showErrorSnackBar('Failed to initialize character system: $e');
    }
  }

  void _onPhonemeChange(String phoneme) {
  // phoneme arrives as one of: mouth_open_a/e/i/o/u, mouth_closed, etc.
  // The animationManager is now managed by CharacterStateProvider,
  // so we don't need to call it directly here.
  _logger.d('👄 Phoneme change -> $phoneme');
}


 void _onCharacterStateChange(String newState) {
  // This callback is now handled by CharacterStateProvider.
  // We can update the UI if needed, but the animation will play automatically.
  _logger.d('🎭 Character state changed to: $newState');
}


  void _onEmotionalToneChange(String newTone) {
    // This callback is now handled by CharacterStateProvider.
    _logger.d('🎭 Emotional tone changed to: $newTone');
  }

  Future<void> _startConversation() async {
    if (!_isInitialized) return;
    
    try {
      // The conversation logic is now handled by CharacterStateProvider.
      // We just need to trigger the state change.
      final characterStateNotifier = ref.read(characterStateProvider.notifier);
      await characterStateNotifier.startConversation();
      
    } catch (e) {
      _logger.e('❌ Error in conversation flow: $e');
      _showErrorSnackBar('Conversation error: $e');
    }
  }

  Future<void> _showEmotionalResponse(String emotion) async {
    if (!_isInitialized) return;
    
    try {
      final characterStateNotifier = ref.read(characterStateProvider.notifier);
      await characterStateNotifier.showEmotionalResponse(emotion);
    } catch (e) {
      _logger.e('❌ Error showing emotional response: $e');
    }
  }

  void _toggleTalking() {
    setState(() {
      _isTalking = !_isTalking;
    });
    _logger.d('Talking state toggled: $_isTalking');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes - this will only trigger once due to state management
    ref.listen(characterStateProvider, (previous, next) {
      if (mounted && next.isInitialized && !_isInitialized) {
        setState(() {
          _isInitialized = next.isInitialized;
        });
        
        if (next.isInitialized) {
          _fadeController.forward();
          _logger.i('🎭 Character system initialized successfully');
        }
      }
    });

    return Scaffold(
      backgroundColor: PediatricTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Single character display area
                _buildCharacterArea(),
                
                // Control panel
                _buildControlPanel(),
                
                // Conversation area
                _buildConversationArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PediatricTheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Main header row
          Row(
            children: [
              Icon(
                Icons.medical_services,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Care',
                      style: PediatricTheme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your Pediatric Health Assistant',
                      style: PediatricTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(),
            ],
          ),
          
          // Performance monitoring widget (development only)
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            _buildPerformanceMonitor(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    // Use ref.watch for UI updates that should rebuild
    final characterState = ref.watch(characterStateProvider);
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (!_isInitialized) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Initializing';
    } else if (characterState.isSpeaking) {
      statusColor = Colors.green;
      statusIcon = Icons.record_voice_over;
      statusText = 'Speaking';
    } else if (characterState.isListening) {
      statusColor = Colors.blue;
      statusIcon = Icons.hearing;
      statusText = 'Listening';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.check_circle;
      statusText = 'Ready';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMonitor() {
    return Consumer(
      builder: (context, ref, child) {
        final performanceSummary = PerformanceMonitorService.instance.getPerformanceSummary();
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Performance Monitor',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Memory',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${performanceSummary.averageMemoryMB.toStringAsFixed(1)} MB',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CPU',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${performanceSummary.averageCpuPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Snapshots',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${performanceSummary.snapshotCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

   Widget _buildCharacterArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character display with scale animation
          ScaleTransition(
            scale: _scaleAnimation,
            child: _buildCharacterDisplay(),
          ),
          
          const SizedBox(height: 24),
          
          // Character state indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: PediatricTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: PediatricTheme.primary.withOpacity(0.3),
              ),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final characterState = ref.watch(characterStateProvider);
                return Text(
                  'State: ${characterState.currentState.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PediatricTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build character display - shows actual 3D mouse model when available
  Widget _buildCharacterDisplay() {
    return Consumer(
      builder: (context, ref, child) {
        final animationManager = ref.watch(riveAnimationManagerProvider);
        
        // Always show 3D model since we have GLTF files - bypass Rive manager check
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 400), // Increased from 200 for full-screen experience
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Full-screen 3D Mouse Model Viewer using Mouse3D widget
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Mouse3D(
                      onReady: (controller) {
                        _characterAnimator = CharacterAnimator(controller);
                        _logger.i('🎭 3D Character Animator ready');
                        _driveAnimation(); // Drive initial animation
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Character Status and Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Character State Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'State: ${ref.watch(characterStateProvider).currentState.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Talking Control Button
                  GestureDetector(
                    onTap: () => _toggleTalking(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isTalking ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isTalking ? Colors.red : Colors.green).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isTalking ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  
                  // Animation Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.animation,
                          color: Colors.green[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '3D Active',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Character Info
              Text(
                '3D Mouse Character',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'Interactive 3D Model with Real Animations',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiveCharacter() {
    final characterState = ref.read(characterStateProvider);
    final artboard = characterState.riveArtboard;

    if (artboard == null) {
      // Show placeholder character when no Rive artboard is available
      return _buildPlaceholderCharacter();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Rive(
          artboard: artboard,
          fit: BoxFit.contain,
          useArtboardSize: true,
        ),
      ),
    );
  }

  /// Build placeholder character when no Rive animations are available
  Widget _buildPlaceholderCharacter() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: PediatricTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: PediatricTheme.primary,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 80,
            color: PediatricTheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. Healthie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: PediatricTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Character Ready',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PediatricTheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCharacter() {
    return Container(
      color: PediatricTheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(PediatricTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Character...',
            style: PediatricTheme.textTheme.bodyLarge?.copyWith(
              color: PediatricTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Character state controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStateButton('idle', 'Idle', Icons.person),
              _buildStateButton('listening', 'Listen', Icons.hearing),
              _buildStateButton('speaking', 'Speak', Icons.record_voice_over),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStateButton('thinking', 'Think', Icons.psychology),
              _buildStateButton('concerned', 'Concerned', Icons.sentiment_dissatisfied),
              _buildStateButton('happy', 'Happy', Icons.sentiment_satisfied),
            ],
          ),
          const SizedBox(height: 16),
          
          // Performance monitoring controls (development only)
          if (kDebugMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPerformanceButton(),
                _buildClearPerformanceButton(),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Main action button
          SizedBox(
            width: double.infinity,
            child: GFButton(
              onPressed: _isInitialized ? _startConversation : null,
              text: 'Start Conversation',
              icon: Icon(
                _isInitialized ? Icons.chat : Icons.hourglass_empty,
                color: Colors.white,
              ),
              size: GFSize.LARGE,
              color: PediatricTheme.primary,
              shape: GFButtonShape.pills,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateButton(String state, String label, IconData icon) {
    final characterState = ref.read(characterStateProvider);
    final isActive = characterState.currentState == state;
    
    return GFButton(
      onPressed: _isInitialized
          ? () async {
              try {
                final characterStateNotifier = ref.read(characterStateProvider.notifier);
                await characterStateNotifier.changeState(state);
              } catch (e) {
                _showErrorSnackBar('Failed to change state: $e');
              }
            }
          : null,
      text: label,
      icon: Icon(icon, size: 16),
      size: GFSize.SMALL,
      color: isActive ? PediatricTheme.primary : PediatricTheme.surface,
      textColor: isActive ? Colors.white : PediatricTheme.onSurface,
      shape: GFButtonShape.pills,
    );
  }

  Widget _buildPerformanceButton() {
    return GFButton(
      onPressed: () {
        PerformanceMonitorService.instance.startMonitoring(interval: const Duration(seconds: 10));
        _showSnackBar('Performance monitoring started (interval: 10s)');
      },
      text: 'Start Perf',
      icon: Icon(Icons.speed, color: Colors.white),
      size: GFSize.SMALL,
      color: Colors.green,
      shape: GFButtonShape.pills,
    );
  }

  Widget _buildClearPerformanceButton() {
    return GFButton(
      onPressed: () {
        PerformanceMonitorService.instance.clearData();
        _showSnackBar('Performance data cleared');
      },
      text: 'Clear Perf',
      icon: Icon(Icons.clear_all, color: Colors.white),
      size: GFSize.SMALL,
      color: Colors.red,
      shape: GFButtonShape.pills,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildConversationArea() {
    return Consumer(
      builder: (context, ref, child) {
        final characterState = ref.watch(characterStateProvider);
        
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PediatricTheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conversation',
                style: PediatricTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Current message
              if (characterState.currentMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PediatricTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PediatricTheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    characterState.currentMessage,
                    style: PediatricTheme.textTheme.bodyMedium,
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Conversation history
              Expanded(
                child: ListView.builder(
                  itemCount: characterState.conversationHistory.length,
                  itemBuilder: (context, index) {
                    final message = characterState.conversationHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message,
                        style: PediatricTheme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Stop performance monitoring
    if (kDebugMode) {
      PerformanceMonitorService.instance.stopMonitoring();
    }
    
    // Stop all animations before disposing to prevent memory leaks
    _fadeController.stop();
    _scaleController.stop();
    
    // Dispose animation controllers
    _fadeController.dispose();
    _scaleController.dispose();
    
    // Dispose Rive controllers
    _riveController?.dispose();
    _stateMachineController?.dispose();
    
    // Dispose character animator
    _characterAnimator?.dispose();
    
    // Clear references to prevent memory leaks
    _characterAnimator = null;
    _riveController = null;
    _stateMachineController = null;
    
    super.dispose();
  }
}
