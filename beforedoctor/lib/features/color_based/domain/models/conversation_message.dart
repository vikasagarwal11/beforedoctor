/// Conversation message model for chat display
class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Helper method to format timestamps
String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  
  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}
