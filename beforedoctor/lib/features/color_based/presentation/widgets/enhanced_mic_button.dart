import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_theme.dart';

/// Enhanced Mic Button with Haptics, Accessibility, and Pediatric Clinic Theme
class EnhancedMicButton extends StatelessWidget {
  final AppStatus status;
  final VoidCallback onTapStartListening;
  final VoidCallback onLongPressStop;
  final double size;
  final bool showPulse;
  final bool enabled; // NEW: allow disabling when needed

  const EnhancedMicButton({
    super.key,
    required this.status,
    required this.onTapStartListening,
    required this.onLongPressStop,
    this.size = 180,
    this.showPulse = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = statusColor(status);
    final isListening = status == AppStatus.listening;

    final label = isListening
        ? l10n.mic_button_listening           // e.g. "Listening"
        : l10n.mic_button_ready;              // e.g. "Tap to talk"
    final hint = isListening
        ? l10n.mic_button_listening_hint      // e.g. "Hold the button to stop listening."
        : l10n.mic_button_ready_hint;         // e.g. "Tap once and then speak."

    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // tap-to-start only when not listening and enabled
            onTap: enabled && !isListening
                ? () {
                    HapticFeedback.lightImpact();
                    onTapStartListening();
                  }
                : null,
            // long-press-to-stop only when listening and enabled
            onLongPress: enabled && isListening
                ? () {
                    HapticFeedback.heavyImpact();
                    onLongPressStop();
                  }
                : null,
            borderRadius: BorderRadius.circular(size / 2),
            focusColor: color.withOpacity(0.10),
            hoverColor: color.withOpacity(0.06),
            splashColor: color.withOpacity(0.12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: size,
                height: size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: (enabled
                          ? (isListening ? color.withOpacity(0.20) : color.withOpacity(0.12))
                          : color.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(size / 2),
                  border: Border.all(
                    color: color.withOpacity(enabled ? 0.35 : 0.20),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(isListening ? 0.35 : 0.22),
                      blurRadius: isListening ? 28 : 18,
                      spreadRadius: isListening ? 2 : 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Always a mic (kid-friendly); we use fill/glow to convey listening
                    Icon(
                      Icons.mic_rounded,
                      color: enabled ? color : color.withOpacity(0.5),
                      size: size * 0.35,
                    ),

                    // Subtle pulse only when not listening & enabled
                    if (showPulse && !isListening && enabled)
                      ExcludeSemantics(child: _subtlePulse(color)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _subtlePulse(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1.16),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Transform.scale(
        scale: v,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
        ),
      ),
    );
  }
}
