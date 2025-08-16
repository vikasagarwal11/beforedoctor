// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get app_title => 'Dr. Healthie';

  @override
  String get app_subtitle => 'Aplicación de Salud por Voz';

  @override
  String get mic_button_listening => 'Escuchando';

  @override
  String get mic_button_ready => 'Toca para hablar';

  @override
  String get mic_button_listening_hint => 'Mantén presionado el botón para dejar de escuchar.';

  @override
  String get mic_button_ready_hint => 'Toca una vez y luego habla.';

  @override
  String get mic_button_accessibility => 'Botón del micrófono para entrada de voz';

  @override
  String get status_ready => 'Listo';

  @override
  String get status_listening_child => 'Te estoy escuchando';

  @override
  String get status_listening_parent => 'Escuchando';

  @override
  String get status_processing_child => 'Pensando...';

  @override
  String get status_processing_parent => 'Procesando...';

  @override
  String get status_speaking_child => 'Déjame contarte';

  @override
  String get status_speaking_parent => 'Hablando...';

  @override
  String get status_complete_child => '¡Todo listo!';

  @override
  String get status_complete_parent => 'Completado';

  @override
  String get status_concern_child => 'Vamos a contarle a un adulto';

  @override
  String get status_concern_parent => 'Preocupación anotada';

  @override
  String get character_state => 'Personaje';

  @override
  String get language_label => 'Idioma';

  @override
  String get status_label => 'Estado';

  @override
  String get conversation_header => 'Conversación';

  @override
  String get conversation_start => 'Toca \"Iniciar Conversación\" para comenzar';

  @override
  String get conversation_you_said => 'Dijiste:';

  @override
  String get conversation_response => 'Respuesta:';

  @override
  String get conversation_processing => 'Procesando...';

  @override
  String get error_loading_model => 'Error al Cargar Modelo 3D';

  @override
  String get loading_3d_character => 'Cargando Personaje 3D...';

  @override
  String selected_character(String character) {
    return 'Seleccionado: $character';
  }

  @override
  String get start_conversation => 'Iniciar Conversación';

  @override
  String get stop_listening => 'Dejar de Escuchar';

  @override
  String get audience_kid => 'Modo Niño';

  @override
  String get audience_parent => 'Modo Padre';

  @override
  String get page_chat => 'Chat';

  @override
  String get page_insights => 'Información';

  @override
  String get page_log => 'Registro';

  @override
  String get page_settings => 'Configuración';

  @override
  String get prompt_1_child => 'Di \'ay\' si algo te duele';

  @override
  String get prompt_2_child => 'Dime qué te molesta';

  @override
  String get prompt_3_child => 'Señala y dime dónde te duele';

  @override
  String get prompt_4_child => '¿Es poco, medio o mucho?';

  @override
  String get prompt_5_child => '¿Otras sensaciones en la barriga o garganta?';

  @override
  String get prompt_1_parent => 'Describe el síntoma con tus propias palabras';

  @override
  String get prompt_2_parent => '¿Cuánto tiempo lleva pasando?';

  @override
  String get prompt_3_parent => '¿Fiebre, sarpullido, vómitos o dificultad para respirar?';

  @override
  String get prompt_4_parent => '¿Algo que lo mejore o empeore?';

  @override
  String get feedback_1_child => '¡Entendido! Estoy pensando...';

  @override
  String get feedback_2_child => '¡Gracias! Te diré qué pienso.';

  @override
  String get feedback_3_child => 'Buen trabajo. Probemos una pregunta más.';

  @override
  String get feedback_1_parent => 'Te escuché. Analizando ahora...';

  @override
  String get feedback_2_parent => 'Esto es lo que estoy viendo.';

  @override
  String get feedback_3_parent => 'Una pregunta más para aclararlo.';

  @override
  String get concern_child => 'Vamos a contarle a un adulto ahora mismo.';

  @override
  String get concern_parent => 'Esto podría necesitar atención inmediata. Considera llamar a tu pediatra o urgencias.';

  @override
  String get a11y_tap_to_talk_label => 'Toca para hablar';

  @override
  String get a11y_tap_to_talk_hint => 'Toca una vez y luego habla';

  @override
  String get a11y_listening_label => 'Escuchando. Mantén presionado para parar.';

  @override
  String get a11y_listening_hint => 'Mantén el botón para dejar de escuchar.';
}
