import 'package:audio_session/audio_session.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class VoceAudioService {
  static final VoceAudioService _voceAudioService =
      VoceAudioService._internal();

  factory VoceAudioService() {
    return _voceAudioService;
  }

  VoceAudioService._internal();

  final Set<PlayerController> _controllers = {};

  void addController(PlayerController controller) {
    _controllers.add(controller);
  }

  void removeController(PlayerController controller) {
    _controllers.remove(controller);
  }

  void play(PlayerController controller) async {
    _controllers.add(controller);
    for (final each in _controllers) {
      if (each != controller) {
        each.pausePlayer();
      }
    }

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    await controller.startPlayer(finishMode: FinishMode.pause);
  }

  void stop() async {
    for (final each in _controllers) {
      each.pausePlayer();
    }
  }

  void clear() {
    for (final each in _controllers) {
      each.pausePlayer();
    }
    _controllers.clear();
  }
}
