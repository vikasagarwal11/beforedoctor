import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('zh')
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Dr. Healthie'**
  String get app_title;

  /// No description provided for @app_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice-Driven Health App'**
  String get app_subtitle;

  /// No description provided for @mic_button_listening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get mic_button_listening;

  /// No description provided for @mic_button_ready.
  ///
  /// In en, this message translates to:
  /// **'Tap to talk'**
  String get mic_button_ready;

  /// No description provided for @mic_button_listening_hint.
  ///
  /// In en, this message translates to:
  /// **'Hold the button to stop listening.'**
  String get mic_button_listening_hint;

  /// No description provided for @mic_button_ready_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap once and then speak.'**
  String get mic_button_ready_hint;

  /// No description provided for @mic_button_accessibility.
  ///
  /// In en, this message translates to:
  /// **'Microphone button for voice input'**
  String get mic_button_accessibility;

  /// No description provided for @status_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get status_ready;

  /// No description provided for @status_listening_child.
  ///
  /// In en, this message translates to:
  /// **'I\'m listening'**
  String get status_listening_child;

  /// No description provided for @status_listening_parent.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get status_listening_parent;

  /// No description provided for @status_processing_child.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get status_processing_child;

  /// No description provided for @status_processing_parent.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get status_processing_parent;

  /// No description provided for @status_speaking_child.
  ///
  /// In en, this message translates to:
  /// **'Let me tell you'**
  String get status_speaking_child;

  /// No description provided for @status_speaking_parent.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get status_speaking_parent;

  /// No description provided for @status_complete_child.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get status_complete_child;

  /// No description provided for @status_complete_parent.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get status_complete_parent;

  /// No description provided for @status_concern_child.
  ///
  /// In en, this message translates to:
  /// **'Let\'s tell a grown-up'**
  String get status_concern_child;

  /// No description provided for @status_concern_parent.
  ///
  /// In en, this message translates to:
  /// **'Concern noted'**
  String get status_concern_parent;

  /// No description provided for @character_state.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get character_state;

  /// No description provided for @language_label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_label;

  /// No description provided for @status_label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status_label;

  /// No description provided for @conversation_header.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversation_header;

  /// No description provided for @conversation_start.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Start Conversation\" to begin'**
  String get conversation_start;

  /// No description provided for @conversation_you_said.
  ///
  /// In en, this message translates to:
  /// **'You said:'**
  String get conversation_you_said;

  /// No description provided for @conversation_response.
  ///
  /// In en, this message translates to:
  /// **'Response:'**
  String get conversation_response;

  /// No description provided for @conversation_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get conversation_processing;

  /// No description provided for @error_loading_model.
  ///
  /// In en, this message translates to:
  /// **'Error Loading 3D Model'**
  String get error_loading_model;

  /// No description provided for @loading_3d_character.
  ///
  /// In en, this message translates to:
  /// **'Loading 3D Character...'**
  String get loading_3d_character;

  /// Shows which 3D character is selected
  ///
  /// In en, this message translates to:
  /// **'Selected: {character}'**
  String selected_character(String character);

  /// No description provided for @start_conversation.
  ///
  /// In en, this message translates to:
  /// **'Start Conversation'**
  String get start_conversation;

  /// No description provided for @stop_listening.
  ///
  /// In en, this message translates to:
  /// **'Stop Listening'**
  String get stop_listening;

  /// No description provided for @audience_kid.
  ///
  /// In en, this message translates to:
  /// **'Kid Mode'**
  String get audience_kid;

  /// No description provided for @audience_parent.
  ///
  /// In en, this message translates to:
  /// **'Parent Mode'**
  String get audience_parent;

  /// No description provided for @page_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get page_chat;

  /// No description provided for @page_insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get page_insights;

  /// No description provided for @page_log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get page_log;

  /// No description provided for @page_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get page_settings;

  /// No description provided for @prompt_1_child.
  ///
  /// In en, this message translates to:
  /// **'Say \'ouch\' if something hurts'**
  String get prompt_1_child;

  /// No description provided for @prompt_2_child.
  ///
  /// In en, this message translates to:
  /// **'Tell me what\'s bothering you'**
  String get prompt_2_child;

  /// No description provided for @prompt_3_child.
  ///
  /// In en, this message translates to:
  /// **'Point and tell me where it hurts'**
  String get prompt_3_child;

  /// No description provided for @prompt_4_child.
  ///
  /// In en, this message translates to:
  /// **'Is it a little, medium, or a lot?'**
  String get prompt_4_child;

  /// No description provided for @prompt_5_child.
  ///
  /// In en, this message translates to:
  /// **'Any other tummy or throat feelings?'**
  String get prompt_5_child;

  /// No description provided for @prompt_1_parent.
  ///
  /// In en, this message translates to:
  /// **'Describe the symptom in your own words'**
  String get prompt_1_parent;

  /// No description provided for @prompt_2_parent.
  ///
  /// In en, this message translates to:
  /// **'How long has this been going on?'**
  String get prompt_2_parent;

  /// No description provided for @prompt_3_parent.
  ///
  /// In en, this message translates to:
  /// **'Any fever, rash, vomiting, or trouble breathing?'**
  String get prompt_3_parent;

  /// No description provided for @prompt_4_parent.
  ///
  /// In en, this message translates to:
  /// **'Anything that makes it better or worse?'**
  String get prompt_4_parent;

  /// No description provided for @feedback_1_child.
  ///
  /// In en, this message translates to:
  /// **'Got it! I\'m thinking...'**
  String get feedback_1_child;

  /// No description provided for @feedback_2_child.
  ///
  /// In en, this message translates to:
  /// **'Thanks! I\'ll tell you what I think.'**
  String get feedback_2_child;

  /// No description provided for @feedback_3_child.
  ///
  /// In en, this message translates to:
  /// **'Nice job. Let\'s try one more question.'**
  String get feedback_3_child;

  /// No description provided for @feedback_1_parent.
  ///
  /// In en, this message translates to:
  /// **'Heard you. Analyzing now...'**
  String get feedback_1_parent;

  /// No description provided for @feedback_2_parent.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what I\'m seeing.'**
  String get feedback_2_parent;

  /// No description provided for @feedback_3_parent.
  ///
  /// In en, this message translates to:
  /// **'One follow-up to make it clearer.'**
  String get feedback_3_parent;

  /// No description provided for @concern_child.
  ///
  /// In en, this message translates to:
  /// **'Let\'s tell a grown-up right away.'**
  String get concern_child;

  /// No description provided for @concern_parent.
  ///
  /// In en, this message translates to:
  /// **'This might need prompt attention. Consider calling your pediatrician or urgent care.'**
  String get concern_parent;

  /// No description provided for @a11y_tap_to_talk_label.
  ///
  /// In en, this message translates to:
  /// **'Tap to talk'**
  String get a11y_tap_to_talk_label;

  /// No description provided for @a11y_tap_to_talk_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap once and then speak'**
  String get a11y_tap_to_talk_hint;

  /// No description provided for @a11y_listening_label.
  ///
  /// In en, this message translates to:
  /// **'Listening. Long press to stop.'**
  String get a11y_listening_label;

  /// No description provided for @a11y_listening_hint.
  ///
  /// In en, this message translates to:
  /// **'Hold the button to stop listening.'**
  String get a11y_listening_hint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr', 'hi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
