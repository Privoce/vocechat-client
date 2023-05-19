import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/services/voce_audio_service.dart';

class VoceProgressBar extends StatefulWidget {
  final int duration;

  final AudioPlayer player;
  final AlignmentGeometry textAlignment;
  final double height;

  const VoceProgressBar({
    super.key,
    required this.player,
    required this.duration,
    required this.height,
    this.textAlignment = Alignment.centerLeft,
  });

  @override
  State<VoceProgressBar> createState() => _VoceProgressBarState();
}

class _VoceProgressBarState extends State<VoceProgressBar>
    with SingleTickerProviderStateMixin {
  // late AnimationController _animationController;

  double _progress = 0.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    widget.player.onPlayerStateChanged.listen((event) {
      if (mounted) {
        setState(() {
          if (event == PlayerState.playing) {
            _isPlaying = true;
          } else {
            _isPlaying = false;
          }
        });
      }
    });

    widget.player.onPositionChanged.listen((event) {
      if (mounted) {
        setState(() {
          _progress = event.inMilliseconds / widget.duration;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        if (mounted) {
          setState(() {
            _isPlaying = !_isPlaying;
          });
        }

        if (_isPlaying) {
          if (_progress > 0.97) {
            _progress = 0;
          }
          VoceAudioService().play(widget.player);
        } else {
          VoceAudioService().stop();
        }
      },
      // onHorizontalDragDown: (details) {
      //   print('onHorizontalDragDown');

      //   // _animationController.stop();
      //   // setState(() {
      //   //   _isPlaying = false;
      //   // });
      // },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        print('onHorizontalDragUpdate');

        double p = (details.localPosition.dx / context.size!.width);
        if (p < 0) {
          p = 0;
        } else if (p > 1) {
          p = 1;
        }
        final duration = Duration(milliseconds: (p * widget.duration).floor());

        widget.player.seek(duration);
      },
      // onHorizontalDragEnd: (DragEndDetails details) {
      //   print('onHorizontalDragEnd');
      //   int progressInMillisecs = (_progress * widget.duration).floor();
      //   widget.onDragEnd(progressInMillisecs);
      // },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: Stack(
          children: [
            Container(
              height: widget.height,
              color: Colors.grey[200],
              child: SizedBox(
                width: double.maxFinite,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5.0),
                        bottomLeft: Radius.circular(5.0),
                      ),
                      color: Colors.blue[200],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: widget.height,
              alignment: widget.textAlignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  millisecToTime(widget.duration),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String millisecToTime(int millisecs) {
    final seconds = (millisecs / 1000).ceil();
    final minutes = seconds ~/ 60;
    final secondsLeft = seconds % 60;

    return "$minutes:${secondsLeft.toString().padLeft(2, '0')}";
  }
}
