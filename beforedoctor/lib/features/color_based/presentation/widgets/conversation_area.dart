import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/app_models.dart';
import '../../domain/models/conversation_message.dart';

/// Conversation area widget for chat display
class ConversationArea extends StatelessWidget {
  final List<ConversationMessage> messages;
  final Audience audience;

  const ConversationArea({
    super.key,
    required this.messages,
    required this.audience,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.isUser;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Flexible to prevent overflow and constrain bubble width
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75, // Max 75% of screen width
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? ClinicColors.speak.withOpacity(0.36)
                        : ClinicColors.mint.withOpacity(0.36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUser 
                          ? ClinicColors.speak.withOpacity(0.5)
                          : ClinicColors.mint.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: ClinicColors.white,
                          fontSize: 15,
                        ),
                        // Add text wrapping to prevent overflow
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: ClinicColors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
