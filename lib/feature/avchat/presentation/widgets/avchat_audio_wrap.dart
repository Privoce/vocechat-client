import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_bloc.dart';

import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_states.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/avchat_user_audio_tile.dart';

class AvchatAudioWrap extends StatelessWidget {
  const AvchatAudioWrap({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AvchatBloc, AvchatState>(
      buildWhen: (previous, current) {
        return current is AgoraInitialized ||
            current is AgoraSelfJoined ||
            current is AgoraGuestJoined ||
            current is AgoraGuestLeft ||
            current is AvchatUserChangeState;
      },
      builder: (context, state) {
        final bloc = context.read<AvchatBloc>();
        final userList = bloc.userList;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(userList.length, (index) {
            final user = userList[index];
            return AvchatUserAudioTile(user: user);
          }),
        );
      },
    );
  }
}
