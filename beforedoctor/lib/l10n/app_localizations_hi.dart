// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get app_title => 'डॉक्टर से पहले';

  @override
  String get app_subtitle => 'आवाज से चलने वाला स्वास्थ्य ऐप';

  @override
  String get mic_button_listening => 'सुन रहा है';

  @override
  String get mic_button_ready => 'बात करने के लिए टैप करें';

  @override
  String get mic_button_listening_hint => 'सुनना बंद करने के लिए बटन को लंबे समय तक दबाएं।';

  @override
  String get mic_button_ready_hint => 'एक बार टैप करें और फिर बोलें।';

  @override
  String get mic_button_accessibility => 'आवाज इनपुट के लिए माइक्रोफोन बटन';

  @override
  String get status_ready => 'तैयार';

  @override
  String get status_listening_child => 'मैं सुन रहा हूं';

  @override
  String get status_listening_parent => 'सुन रहा है';

  @override
  String get status_processing_child => 'सोच रहा हूं...';

  @override
  String get status_processing_parent => 'प्रोसेसिंग...';

  @override
  String get status_speaking_child => 'मुझे बताने दो';

  @override
  String get status_speaking_parent => 'बोल रहा है...';

  @override
  String get status_complete_child => 'हो गया!';

  @override
  String get status_complete_parent => 'पूरा';

  @override
  String get status_concern_child => 'चलो बड़ों को बताते हैं';

  @override
  String get status_concern_parent => 'चिंता दर्ज की गई';

  @override
  String get character_state => 'पात्र';

  @override
  String get language_label => 'भाषा';

  @override
  String get status_label => 'स्थिति';

  @override
  String get conversation_header => 'बातचीत';

  @override
  String get conversation_start => 'शुरू करने के लिए \"बातचीत शुरू करें\" पर टैप करें';

  @override
  String get conversation_you_said => 'आपने कहा:';

  @override
  String get conversation_response => 'जवाब:';

  @override
  String get conversation_processing => 'प्रोसेसिंग...';

  @override
  String get error_loading_model => '3D मॉडल लोड करने में त्रुटि';

  @override
  String get loading_3d_character => '3D पात्र लोड हो रहा है...';

  @override
  String selected_character(String character) {
    return 'चयनित: $character';
  }

  @override
  String get start_conversation => 'बातचीत शुरू करें';

  @override
  String get stop_listening => 'सुनना बंद करें';

  @override
  String get audience_kid => 'बच्चा मोड';

  @override
  String get audience_parent => 'माता-पिता मोड';

  @override
  String get page_chat => 'चैट';

  @override
  String get page_insights => 'अंतर्दृष्टि';

  @override
  String get page_log => 'लॉग';

  @override
  String get page_settings => 'सेटिंग्स';

  @override
  String get prompt_1_child => 'अगर कुछ दर्द करता है तो \'आह\' कहो';

  @override
  String get prompt_2_child => 'मुझे बताओ क्या परेशान कर रहा है';

  @override
  String get prompt_3_child => 'इशारा करो और बताओ कहां दर्द करता है';

  @override
  String get prompt_4_child => 'क्या यह थोड़ा, मध्यम या बहुत है?';

  @override
  String get prompt_5_child => 'पेट या गले में कोई और भावना?';

  @override
  String get prompt_1_parent => 'अपने शब्दों में लक्षण का वर्णन करें';

  @override
  String get prompt_2_parent => 'यह कब से चल रहा है?';

  @override
  String get prompt_3_parent => 'बुखार, चकत्ते, उल्टी या सांस लेने में तकलीफ?';

  @override
  String get prompt_4_parent => 'कुछ ऐसा जो इसे बेहतर या बदतर बनाता है?';

  @override
  String get feedback_1_child => 'समझ गया! मैं सोच रहा हूं...';

  @override
  String get feedback_2_child => 'धन्यवाद! मैं आपको बताऊंगा कि मैं क्या सोचता हूं।';

  @override
  String get feedback_3_child => 'अच्छा काम। एक और सवाल आज़माते हैं।';

  @override
  String get feedback_1_parent => 'सुना। अभी विश्लेषण कर रहा हूं...';

  @override
  String get feedback_2_parent => 'यह मैं देख रहा हूं।';

  @override
  String get feedback_3_parent => 'एक और सवाल स्थिति को स्पष्ट करने के लिए।';

  @override
  String get concern_child => 'चलो अभी बड़ों को बताते हैं।';

  @override
  String get concern_parent => 'इसे तत्काल ध्यान की आवश्यकता हो सकती है। अपने बाल रोग विशेषज्ञ या आपातकालीन देखभाल को कॉल करने पर विचार करें।';

  @override
  String get a11y_tap_to_talk_label => 'बात करने के लिए टैप करें';

  @override
  String get a11y_tap_to_talk_hint => 'एक बार टैप करें और फिर बोलें';

  @override
  String get a11y_listening_label => 'सुन रहा है। रोकने के लिए लंबे समय तक दबाएं।';

  @override
  String get a11y_listening_hint => 'सुनना बंद करने के लिए बटन को पकड़ें.';
}
