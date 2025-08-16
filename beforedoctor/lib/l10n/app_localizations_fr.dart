// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get app_title => 'AvantLeMédecin';

  @override
  String get app_subtitle => 'Application de Santé Pilotée par la Voix';

  @override
  String get mic_button_listening => 'Écoute';

  @override
  String get mic_button_ready => 'Appuyez pour parler';

  @override
  String get mic_button_listening_hint => 'Maintenez le bouton enfoncé pour arrêter d\'écouter.';

  @override
  String get mic_button_ready_hint => 'Appuyez une fois puis parlez.';

  @override
  String get mic_button_accessibility => 'Bouton du microphone pour saisie vocale';

  @override
  String get status_ready => 'Prêt';

  @override
  String get status_listening_child => 'Je t\'écoute';

  @override
  String get status_listening_parent => 'Écoute';

  @override
  String get status_processing_child => 'Je réfléchis...';

  @override
  String get status_processing_parent => 'Traitement...';

  @override
  String get status_speaking_child => 'Laisse-moi te dire';

  @override
  String get status_speaking_parent => 'Parle...';

  @override
  String get status_complete_child => 'C\'est fini !';

  @override
  String get status_complete_parent => 'Terminé';

  @override
  String get status_concern_child => 'Disons-le à un adulte';

  @override
  String get status_concern_parent => 'Préoccupation notée';

  @override
  String get character_state => 'Personnage';

  @override
  String get language_label => 'Langue';

  @override
  String get status_label => 'État';

  @override
  String get conversation_header => 'Conversation';

  @override
  String get conversation_start => 'Appuyez sur \"Commencer la Conversation\" pour commencer';

  @override
  String get conversation_you_said => 'Vous avez dit :';

  @override
  String get conversation_response => 'Réponse :';

  @override
  String get conversation_processing => 'Traitement...';

  @override
  String get error_loading_model => 'Erreur de Chargement du Modèle 3D';

  @override
  String get loading_3d_character => 'Chargement du Personnage 3D...';

  @override
  String selected_character(String character) {
    return 'Sélectionné : $character';
  }

  @override
  String get start_conversation => 'Commencer la Conversation';

  @override
  String get stop_listening => 'Arrêter d\'Écouter';

  @override
  String get audience_kid => 'Mode Enfant';

  @override
  String get audience_parent => 'Mode Parent';

  @override
  String get page_chat => 'Chat';

  @override
  String get page_insights => 'Aperçus';

  @override
  String get page_log => 'Journal';

  @override
  String get page_settings => 'Paramètres';

  @override
  String get prompt_1_child => 'Dis \'aïe\' si quelque chose fait mal';

  @override
  String get prompt_2_child => 'Dis-moi ce qui te dérange';

  @override
  String get prompt_3_child => 'Montre et dis-moi où ça fait mal';

  @override
  String get prompt_4_child => 'C\'est un peu, moyen ou beaucoup ?';

  @override
  String get prompt_5_child => 'D\'autres sensations dans le ventre ou la gorge ?';

  @override
  String get prompt_1_parent => 'Décrivez le symptôme avec vos propres mots';

  @override
  String get prompt_2_parent => 'Depuis combien de temps cela dure-t-il ?';

  @override
  String get prompt_3_parent => 'Fièvre, éruption, vomissements ou difficulté à respirer ?';

  @override
  String get prompt_4_parent => 'Quelque chose qui l\'améliore ou l\'aggrave ?';

  @override
  String get feedback_1_child => 'Compris ! Je réfléchis...';

  @override
  String get feedback_2_child => 'Merci ! Je vais te dire ce que je pense.';

  @override
  String get feedback_3_child => 'Bon travail. Essayons une autre question.';

  @override
  String get feedback_1_parent => 'Entendu. Analyse en cours...';

  @override
  String get feedback_2_parent => 'Voici ce que je vois.';

  @override
  String get feedback_3_parent => 'Une question de plus pour clarifier.';

  @override
  String get concern_child => 'Disons-le à un adulte tout de suite.';

  @override
  String get concern_parent => 'Cela pourrait nécessiter une attention immédiate. Considérez appeler votre pédiatre ou les urgences.';

  @override
  String get a11y_tap_to_talk_label => 'Appuyez pour parler';

  @override
  String get a11y_tap_to_talk_hint => 'Appuyez une fois puis parlez';

  @override
  String get a11y_listening_label => 'Écoute. Appuyez longuement pour arrêter.';

  @override
  String get a11y_listening_hint => 'Maintenez le bouton pour arrêter d\'écouter.';
}
