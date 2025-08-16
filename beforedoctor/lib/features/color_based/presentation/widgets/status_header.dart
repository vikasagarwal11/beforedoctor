import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/app_models.dart';
import '../../../../l10n/app_localizations.dart';

/// Status header widget with live indicator and status display
class StatusHeader extends StatefulWidget {
  final AppStatus currentStatus;
  final Audience audience;
  final Function(AppStatus) onStatusChange;

  const StatusHeader({
    super.key,
    required this.currentStatus,
    required this.audience,
    required this.onStatusChange,
  });

  @override
  State<StatusHeader> createState() => _StatusHeaderState();
}

class _StatusHeaderState extends State<StatusHeader>
    with TickerProviderStateMixin {
  late AnimationController _statusController;
  late Animation<double> _statusAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _statusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusController,
      curve: Curves.easeInOut,
    ));
    
    _statusController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Live indicator with animated bars
          _buildLiveIndicator(),
          
          const Spacer(),
          
          // App title
          _buildAppTitle(),
          
          const Spacer(),
          
          // Status display
          _buildStatusDisplay(),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // Animated bars (only when listening)
          if (widget.currentStatus == AppStatus.listening)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _statusAnimation,
                builder: (context, child) {
                  return Row(
                    children: List.generate(3, (index) {
                      return Container(
                        width: 3,
                        height: 20 * _statusAnimation.value * (0.5 + index * 0.25),
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: ClinicColors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          const SizedBox(width: 8),
          Text(
            'Live',
            style: TextStyle(
              color: ClinicColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTitle() {
    return Text(
      'Dr. Healthie',
      style: TextStyle(
        color: ClinicColors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: softBadge(statusColor(widget.currentStatus)),
      child: Text(
        _getStatusLabel(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getStatusLabel() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return "Ready";

    switch (widget.currentStatus) {
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
