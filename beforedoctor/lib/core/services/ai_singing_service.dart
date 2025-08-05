import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../config/app_config.dart';

class AISingingService {
  static AISingingService? _instance;
  static AISingingService get instance => _instance ??= AISingingService._internal();

  AISingingService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AppConfig _config = AppConfig.instance;

  // ElevenLabs API endpoints
  static const String _elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  
  // Preset voice IDs for different characters
  static const Map<String, String> _voiceIds = {
    'doctor_friendly': 'your_doctor_voice_id',
    'doctor_calm': 'your_calm_voice_id',
    'doctor_singing': 'your_singing_voice_id',
  };

  // Initialize the service
  Future<void> initialize() async {
    // Configure audio session for background playback
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.assistanceNavigationGuidance,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  // Generate and play a calming lullaby based on symptoms
  Future<void> singCalmingLullaby(String symptom, {String? childName}) async {
    try {
      // Generate lyrics based on symptom
      final lyrics = _generateCalmingLyrics(symptom, childName);
      
      // Generate singing audio using ElevenLabs
      final audioData = await _generateSingingAudio(lyrics);
      
      // Play the audio
      await _playAudio(audioData);
      
    } catch (e) {
      print('Error generating singing response: $e');
      // Fallback to regular TTS
      await _fallbackToTTS(symptom);
    }
  }

  // Generate dynamic lyrics based on symptoms
  String _generateCalmingLyrics(String symptom, String? childName) {
    final name = childName ?? 'little one';
    
    switch (symptom.toLowerCase()) {
      case 'fever':
        return '''
          Hush now, $name, don't you cry,
          The fever will pass by and by.
          Rest your head and close your eyes,
          Soon you'll feel better, that's no surprise.
          
          Take deep breaths, one, two, three,
          Let the cool air set you free.
          Mommy's here and Daddy too,
          We'll take good care of you.
        ''';
        
      case 'cough':
        return '''
          Little $name, I hear you cough,
          But don't worry, it won't last long.
          Drink some water, warm and clear,
          Soon your throat will feel better, dear.
          
          Rest your voice and take it slow,
          The cough will go, this much I know.
          We'll make you well, just wait and see,
          You'll be running around, happy and free.
        ''';
        
      case 'pain':
        return '''
          I know it hurts, my little one,
          But the pain will soon be gone.
          Take my hand and hold it tight,
          Everything will be alright.
          
          We'll find what's wrong and make it right,
          You'll feel better with all our might.
          Soon you'll smile and laugh again,
          No more tears, no more pain.
        ''';
        
      default:
        return '''
          Hush now, $name, don't be afraid,
          I'm here to help, I've got it made.
          Whatever hurts, whatever's wrong,
          We'll fix it together, we'll be strong.
          
          Take my hand and trust in me,
          I'll make you better, just wait and see.
          Soon you'll be well and running free,
          Happy and healthy, just like you should be.
        ''';
    }
  }

  // Generate singing audio using ElevenLabs API
  Future<Uint8List> _generateSingingAudio(String lyrics) async {
    final apiKey = _config.elevenLabsApiKey;
    final voiceId = _voiceIds['doctor_singing'] ?? 'default_voice_id';
    
    final url = Uri.parse('$_elevenLabsBaseUrl/text-to-speech/$voiceId');
    
    final response = await http.post(
      url,
      headers: {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': apiKey,
      },
      body: jsonEncode({
        'text': lyrics,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
          'style': 0.0,
          'use_speaker_boost': true,
        },
        'output_format': 'mp3_44100_128',
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to generate singing audio: ${response.statusCode}');
    }
  }

  // Play the generated audio
  Future<void> _playAudio(Uint8List audioData) async {
    try {
      // Convert audio data to audio source
      final audioSource = StreamAudioSource(audioData);
      
      // Set the audio source and play
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
      
    } catch (e) {
      print('Error playing audio: $e');
      throw Exception('Failed to play singing audio');
    }
  }

  // Fallback to regular TTS if singing fails
  Future<void> _fallbackToTTS(String symptom) async {
    // This would integrate with CharacterInteractionEngine
    // For now, just log the fallback
    print('Falling back to regular TTS for symptom: $symptom');
  }

  // Stop current audio playback
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Pause current audio playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // Resume current audio playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  // Check if audio is currently playing
  bool get isPlaying => _audioPlayer.playing;

  // Get current playback position
  Duration? get position => _audioPlayer.position;

  // Get total duration
  Duration? get duration => _audioPlayer.duration;

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

// Custom audio source for playing byte data
class StreamAudioSource extends StreamAudioSource {
  final Uint8List _audioData;
  
  StreamAudioSource(this._audioData);
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _audioData.length;
    
    return StreamAudioResponse(
      sourceLength: _audioData.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_audioData.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
} 