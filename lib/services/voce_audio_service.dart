import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';

class VoceAudioService {
  static final VoceAudioService _voceAudioService =
      VoceAudioService._internal();

  factory VoceAudioService() {
    return _voceAudioService;
  }

  VoceAudioService._internal();

  final Set<AudioPlayer> _players = {};

  void addController(AudioPlayer player) {
    _players.add(player);
  }

  void removeController(AudioPlayer controller) {
    _players.remove(controller);
  }

  void play(AudioPlayer controller) async {
    _players.add(controller);
    for (final each in _players) {
      if (each != controller) {
        each.pause();
      }
    }

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    await controller.resume();

    controller.onPlayerStateChanged.listen((event) {
      // print(event);
    });
  }

  void stop() async {
    for (final each in _players) {
      each.pause();
    }
  }

  void clear() {
    for (final each in _players) {
      each.dispose();
    }
    _players.clear();
  }
}
