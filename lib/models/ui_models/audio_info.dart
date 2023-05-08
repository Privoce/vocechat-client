import 'package:audio_waveforms/audio_waveforms.dart';

class AudioInfo {
  /// The controller of the audio.
  final PlayerController controller;

  /// The duration of the audio in milliseconds.
  final int duration;

  AudioInfo(this.controller, this.duration);
}
