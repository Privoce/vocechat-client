import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_bloc.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_events.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_states.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/avchat_appbar.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/avchat_audio_wrap.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/avchat_status_text.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/round_button.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';

class AvchatPage extends StatefulWidget {
  const AvchatPage({Key? key}) : super(key: key);

  @override
  State<AvchatPage> createState() => _AvchatPageState();
}

class _AvchatPageState extends State<AvchatPage> {
  final enabledForeground = Colors.grey.shade800;
  final enabledBackground = Colors.grey.shade100;
  final disabledForground = Colors.grey.shade100;
  final disabledBackground = Colors.grey.shade600;

  bool _isMicMuted = false;
  bool _isSpeakerMuted = false;

  @override
  initState() {
    super.initState();
    _isMicMuted = context.read<AvchatBloc>().isMicMuted;
    _isSpeakerMuted = context.read<AvchatBloc>().isSpeakerMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AvchatAppBar(
        backButtonPressed: () {
          Navigator.of(context).pop();
          context
              .read<AvchatBloc>()
              .add(AvchatMinimizeRequest(toMinimize: true, context: context));
        },
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvchatAudioWrap(),
          SizedBox(height: 8),
          AvchatStatusText(
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()]))
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.grey[800],
      padding: EdgeInsets.only(bottom: bottomSafeArea, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // _buildSpeakerBtn(),
          _buildMicBtn(),
          _buildEndCallBtn(context)
        ],
      ),
    );
  }

  Widget _buildSpeakerBtn() {
    return BlocBuilder<AvchatBloc, AvchatState>(
      builder: (context, state) {
        if (state is AvchatSpeakerBtnState) {
          _isSpeakerMuted = state.isMuted;
        }
        if (_isSpeakerMuted) {
          return RoundButton(
            icon: AppIcons.speaker_off,
            foregroundColor: disabledForground,
            backgroundColor: disabledBackground,
            onPressed: () {
              context.read<AvchatBloc>().add(AvchatSpeakerBtnPressed(false));
            },
          );
        } else {
          return RoundButton(
            icon: AppIcons.speaker,
            foregroundColor: enabledForeground,
            backgroundColor: enabledBackground,
            onPressed: () {
              context.read<AvchatBloc>().add(AvchatSpeakerBtnPressed(true));
            },
          );
        }
      },
    );
  }

  Widget _buildMicBtn() {
    return BlocBuilder<AvchatBloc, AvchatState>(
      builder: (context, state) {
        if (state is AvchatMicBtnState) {
          _isMicMuted = state.isMuted;
        }
        if (_isMicMuted) {
          return RoundButton(
            icon: AppIcons.mic_off,
            foregroundColor: disabledForground,
            backgroundColor: disabledBackground,
            onPressed: () {
              context.read<AvchatBloc>().add(AvchatMicBtnPressed(false));
            },
          );
        } else {
          return RoundButton(
            icon: AppIcons.mic,
            foregroundColor: enabledForeground,
            backgroundColor: enabledBackground,
            onPressed: () {
              context.read<AvchatBloc>().add(AvchatMicBtnPressed(true));
            },
          );
        }
      },
    );
  }

  RoundButton _buildEndCallBtn(BuildContext context) {
    return RoundButton(
      icon: AppIcons.call_end,
      foregroundColor: Colors.white,
      backgroundColor: Colors.red,
      onPressed: () {
        context.read<AvchatBloc>().add(AvchatEndCallBtnPressed());
        Navigator.of(context).pop();
      },
    );
  }
}
