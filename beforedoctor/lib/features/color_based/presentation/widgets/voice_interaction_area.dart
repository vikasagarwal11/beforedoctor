import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/app_models.dart';
import '../../../../l10n/app_localizations.dart';
import 'enhanced_mic_button.dart';

/// Voice interaction area with mic button and rotating prompts
class VoiceInteractionArea extends StatefulWidget {
  final AppStatus currentStatus;
  final Audience audience;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final Function(AppStatus) onStatusChange; // Add this callback

  const VoiceInteractionArea({
    super.key,
    required this.currentStatus,
    required this.audience,
    required this.onStartListening,
    required this.onStopListening,
    required this.onStatusChange, // Add this parameter
  });

  @override
  State<VoiceInteractionArea> createState() => _VoiceInteractionAreaState();
}

class _VoiceInteractionAreaState extends State<VoiceInteractionArea>
    with TickerProviderStateMixin {
  late AnimationController _textPulseController;
  late Animation<double> _textPulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _textPulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _textPulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _textPulseController,
      curve: Curves.easeInOut,
    ));
    
    _textPulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _textPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Enhanced mic button
        EnhancedMicButton(
          status: widget.currentStatus,
          onTapStartListening: widget.onStartListening,
          onLongPressStop: widget.onStopListening,
          size: 180,
          showPulse: true,
          enabled: widget.currentStatus != AppStatus.processing && 
                   widget.currentStatus != AppStatus.speaking,
        ),
        
        const SizedBox(height: 20),
        
        // Real-time status indicator
        _buildStatusIndicator(),
        
        const SizedBox(height: 20),
        
        // Rotating prompts
        _buildRotatingPrompts(),
        
        const SizedBox(height: 40),
        
        // State testing buttons
        _buildStateTestingButtons(),
      ],
    );
  }

  Widget _buildRotatingPrompts() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _textPulseController,
        builder: (context, child) {
          // Get dynamic content based on current status
          final dynamicContent = _getDynamicContent();
          
          return Text(
            dynamicContent,
            style: TextStyle(
              fontSize: 18,
              color: ClinicColors.white.withOpacity(0.9),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }
  
  /// Get dynamic content based on current AI status
  String _getDynamicContent() {
    switch (widget.currentStatus) {
      case AppStatus.ready:
        return widget.audience == Audience.child 
          ? "Tap the mic and tell me what's wrong!"
          : "Tap the mic to describe your child's symptoms";
          
      case AppStatus.listening:
        return widget.audience == Audience.child 
          ? "I'm listening... tell me more!"
          : "Listening... please describe the symptoms";
          
      case AppStatus.processing:
        return widget.audience == Audience.child 
          ? "Thinking... let me figure this out!"
          : "Processing... analyzing the symptoms";
          
      case AppStatus.speaking:
        return widget.audience == Audience.child 
          ? "Let me tell you what I found!"
          : "Providing medical assessment...";
          
      case AppStatus.complete:
        return widget.audience == Audience.child 
          ? "All done! How are you feeling now?"
          : "Assessment complete. Any other concerns?";
          
      case AppStatus.concerned:
        return widget.audience == Audience.child 
          ? "I'm concerned. Let's get help!"
          : "⚠️ Medical attention may be needed";
          
      default:
        return widget.audience == Audience.child 
          ? "Hello! How can I help you today?"
          : "Ready to assist with your child's health";
    }
  }

  Widget _buildStatusIndicator() {
    String statusText;
    Color statusColor;
    
    switch (widget.currentStatus) {
      case AppStatus.ready:
        statusText = "Ready to help!";
        statusColor = ClinicColors.mint;
        break;
      case AppStatus.listening:
        statusText = "🎧 Listening...";
        statusColor = ClinicColors.sea;
        break;
      case AppStatus.processing:
        statusText = "🧠 Thinking...";
        statusColor = ClinicColors.amber;
        break;
      case AppStatus.speaking:
        statusText = "🗣️ Speaking...";
        statusColor = ClinicColors.speak;
        break;
      case AppStatus.complete:
        statusText = "✅ Done!";
        statusColor = ClinicColors.mint;
        break;
      case AppStatus.concerned:
        statusText = "⚠️ Concern detected!";
        statusColor = ClinicColors.coral;
        break;
      default:
        statusText = "Ready";
        statusColor = ClinicColors.white;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStateTestingButtons() {
    return Column(
      children: [
        // Audience toggle for testing
        _buildAudienceToggle(),
        
        // State testing buttons with tone-adaptive labels
        _buildStateButtons(),
      ],
    );
  }

  Widget _buildAudienceToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ClinicColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ClinicColors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mode: ${widget.audience == Audience.child ? "Kid" : "Parent"}',
            style: TextStyle(
              color: ClinicColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // This will be handled by the parent widget
              // For now, we'll just show the current mode
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ClinicColors.speak.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ClinicColors.speak.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                'Switch',
                style: TextStyle(
                  color: ClinicColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStateButton(_getStatusLabel(AppStatus.ready), AppStatus.ready, ClinicColors.primary),
          _buildStateButton(_getStatusLabel(AppStatus.listening), AppStatus.listening, ClinicColors.sea),
          _buildStateButton(_getStatusLabel(AppStatus.processing), AppStatus.processing, ClinicColors.amber),
          _buildStateButton(_getStatusLabel(AppStatus.complete), AppStatus.complete, ClinicColors.secondary),
          _buildStateButton(_getStatusLabel(AppStatus.concerned), AppStatus.concerned, ClinicColors.coral),
        ],
      ),
    );
  }

  Widget _buildStateButton(String label, AppStatus state, Color color) {
    final isActive = widget.currentStatus == state;
    
    return GestureDetector(
      onTap: () {
        // Now actually call the parent's status change method!
        widget.onStatusChange(state);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: softBadge(isActive ? color : color.withOpacity(0.5)),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : color.withOpacity(0.7),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(AppStatus status) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return "Ready";

    switch (status) {
      case AppStatus.listening:
        return widget.audience == Audience.child 
            ? l10n.status_listening_child 
            : l10n.status_listening_parent;
      case AppStatus.processing:
        return widget.audience == Audience.child 
            ? l10n.status_processing_child 
            : l10n.status_processing_parent;
      case AppStatus.speaking:
        return widget.audience == Audience.child 
            ? l10n.status_speaking_child 
            : l10n.status_speaking_parent;
      case AppStatus.complete:
        return widget.audience == Audience.child 
            ? l10n.status_complete_child 
            : l10n.status_complete_parent;
      case AppStatus.concerned:
        return widget.audience == Audience.child 
            ? l10n.status_concern_child 
            : l10n.status_concern_parent;
      case AppStatus.ready:
      default:
        return l10n.status_ready;
    }
  }
}
