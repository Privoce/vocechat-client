import 'package:audioplayers/audioplayers.dart';

class AudioInfo {
  /// The controller of the audio.
  final AudioPlayer player;

  /// The duration of the audio in milliseconds.
  final int duration;

  AudioInfo(this.player, this.duration);
}
