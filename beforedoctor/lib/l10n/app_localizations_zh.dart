// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_title => '看医生前';

  @override
  String get app_subtitle => '语音驱动健康应用';

  @override
  String get mic_button_listening => '正在听';

  @override
  String get mic_button_ready => '点击说话';

  @override
  String get mic_button_listening_hint => '长按按钮停止听。';

  @override
  String get mic_button_ready_hint => '点击一次然后说话。';

  @override
  String get mic_button_accessibility => '语音输入麦克风按钮';

  @override
  String get status_ready => '就绪';

  @override
  String get status_listening_child => '我在听';

  @override
  String get status_listening_parent => '正在听';

  @override
  String get status_processing_child => '思考中...';

  @override
  String get status_processing_parent => '处理中...';

  @override
  String get status_speaking_child => '让我告诉你';

  @override
  String get status_speaking_parent => '说话中...';

  @override
  String get status_complete_child => '完成了！';

  @override
  String get status_complete_parent => '完成';

  @override
  String get status_concern_child => '让我们告诉大人';

  @override
  String get status_concern_parent => '已记录关注';

  @override
  String get character_state => '角色';

  @override
  String get language_label => '语言';

  @override
  String get status_label => '状态';

  @override
  String get conversation_header => '对话';

  @override
  String get conversation_start => '点击\"开始对话\"开始';

  @override
  String get conversation_you_said => '你说：';

  @override
  String get conversation_response => '回复：';

  @override
  String get conversation_processing => '处理中...';

  @override
  String get error_loading_model => '加载3D模型错误';

  @override
  String get loading_3d_character => '加载3D角色中...';

  @override
  String selected_character(String character) {
    return '已选择：$character';
  }

  @override
  String get start_conversation => '开始对话';

  @override
  String get stop_listening => '停止听';

  @override
  String get audience_kid => '儿童模式';

  @override
  String get audience_parent => '家长模式';

  @override
  String get page_chat => '聊天';

  @override
  String get page_insights => '洞察';

  @override
  String get page_log => '记录';

  @override
  String get page_settings => '设置';

  @override
  String get prompt_1_child => '如果疼就说\'哎哟\'';

  @override
  String get prompt_2_child => '告诉我什么让你烦恼';

  @override
  String get prompt_3_child => '指一指告诉我哪里疼';

  @override
  String get prompt_4_child => '是一点、中等还是很多？';

  @override
  String get prompt_5_child => '肚子或喉咙有其他感觉吗？';

  @override
  String get prompt_1_parent => '用你自己的话描述症状';

  @override
  String get prompt_2_parent => '这种情况持续多久了？';

  @override
  String get prompt_3_parent => '有发烧、皮疹、呕吐或呼吸困难吗？';

  @override
  String get prompt_4_parent => '有什么会让它变好或变坏吗？';

  @override
  String get feedback_1_child => '明白了！我在思考...';

  @override
  String get feedback_2_child => '谢谢！我会告诉你我的想法。';

  @override
  String get feedback_3_child => '做得好。让我们再试一个问题。';

  @override
  String get feedback_1_parent => '听到了。正在分析...';

  @override
  String get feedback_2_parent => '这是我看到的。';

  @override
  String get feedback_3_parent => '再问一个让情况更清楚。';

  @override
  String get concern_child => '让我们马上告诉大人。';

  @override
  String get concern_parent => '这可能需要及时关注。考虑联系儿科医生或急诊。';

  @override
  String get a11y_tap_to_talk_label => '点击说话';

  @override
  String get a11y_tap_to_talk_hint => '点击一次然后说话';

  @override
  String get a11y_listening_label => '正在听。长按停止。';

  @override
  String get a11y_listening_hint => '按住按钮停止听。';
}
