// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Dr. Healthie';

  @override
  String get app_subtitle => 'Voice-Driven Health App';

  @override
  String get mic_button_listening => 'Listening';

  @override
  String get mic_button_ready => 'Tap to talk';

  @override
  String get mic_button_listening_hint => 'Hold the button to stop listening.';

  @override
  String get mic_button_ready_hint => 'Tap once and then speak.';

  @override
  String get mic_button_accessibility => 'Microphone button for voice input';

  @override
  String get status_ready => 'Ready';

  @override
  String get status_listening_child => 'I\'m listening';

  @override
  String get status_listening_parent => 'Listening';

  @override
  String get status_processing_child => 'Thinking...';

  @override
  String get status_processing_parent => 'Processing...';

  @override
  String get status_speaking_child => 'Let me tell you';

  @override
  String get status_speaking_parent => 'Speaking...';

  @override
  String get status_complete_child => 'All done!';

  @override
  String get status_complete_parent => 'Complete';

  @override
  String get status_concern_child => 'Let\'s tell a grown-up';

  @override
  String get status_concern_parent => 'Concern noted';

  @override
  String get character_state => 'Character';

  @override
  String get language_label => 'Language';

  @override
  String get status_label => 'Status';

  @override
  String get conversation_header => 'Conversation';

  @override
  String get conversation_start => 'Tap \"Start Conversation\" to begin';

  @override
  String get conversation_you_said => 'You said:';

  @override
  String get conversation_response => 'Response:';

  @override
  String get conversation_processing => 'Processing...';

  @override
  String get error_loading_model => 'Error Loading 3D Model';

  @override
  String get loading_3d_character => 'Loading 3D Character...';

  @override
  String selected_character(String character) {
    return 'Selected: $character';
  }

  @override
  String get start_conversation => 'Start Conversation';

  @override
  String get stop_listening => 'Stop Listening';

  @override
  String get audience_kid => 'Kid Mode';

  @override
  String get audience_parent => 'Parent Mode';

  @override
  String get page_chat => 'Chat';

  @override
  String get page_insights => 'Insights';

  @override
  String get page_log => 'Log';

  @override
  String get page_settings => 'Settings';

  @override
  String get prompt_1_child => 'Say \'ouch\' if something hurts';

  @override
  String get prompt_2_child => 'Tell me what\'s bothering you';

  @override
  String get prompt_3_child => 'Point and tell me where it hurts';

  @override
  String get prompt_4_child => 'Is it a little, medium, or a lot?';

  @override
  String get prompt_5_child => 'Any other tummy or throat feelings?';

  @override
  String get prompt_1_parent => 'Describe the symptom in your own words';

  @override
  String get prompt_2_parent => 'How long has this been going on?';

  @override
  String get prompt_3_parent => 'Any fever, rash, vomiting, or trouble breathing?';

  @override
  String get prompt_4_parent => 'Anything that makes it better or worse?';

  @override
  String get feedback_1_child => 'Got it! I\'m thinking...';

  @override
  String get feedback_2_child => 'Thanks! I\'ll tell you what I think.';

  @override
  String get feedback_3_child => 'Nice job. Let\'s try one more question.';

  @override
  String get feedback_1_parent => 'Heard you. Analyzing now...';

  @override
  String get feedback_2_parent => 'Here\'s what I\'m seeing.';

  @override
  String get feedback_3_parent => 'One follow-up to make it clearer.';

  @override
  String get concern_child => 'Let\'s tell a grown-up right away.';

  @override
  String get concern_parent => 'This might need prompt attention. Consider calling your pediatrician or urgent care.';

  @override
  String get a11y_tap_to_talk_label => 'Tap to talk';

  @override
  String get a11y_tap_to_talk_hint => 'Tap once and then speak';

  @override
  String get a11y_listening_label => 'Listening. Long press to stop.';

  @override
  String get a11y_listening_hint => 'Hold the button to stop listening.';
}
