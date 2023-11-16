import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_bloc.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_events.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_states.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/avchat_appbar.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/avchat_status_text.dart';
import 'package:vocechat_client/feature/avchat/presentation/widgets/round_button.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

class AvchatPage extends StatefulWidget {
  const AvchatPage({Key? key}) : super(key: key);

  @override
  State<AvchatPage> createState() => _AvchatPageState();
}

class _AvchatPageState extends State<AvchatPage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(seconds: 1),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AvchatAppBar(
        backButtonPressed: () {
          Navigator.of(context).pop();
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
          VoceUserAvatar(size: 56, uid: 1, enableOnlineStatus: false),
          SizedBox(height: 16),
          Text(
            'name',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text("on going call"),
          AvchatStatusText()
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // final bloc = BlocProvider.of(context).read<AvchatBloc>();
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    final enabledForeground = Colors.grey.shade800;
    final enabledBackground = Colors.grey.shade100;
    final disabledForground = Colors.grey.shade100;
    final disabledBackground = Colors.grey.shade600;

    return Container(
      color: Colors.grey[800],
      padding: EdgeInsets.only(bottom: bottomSafeArea, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RoundButton(icon: AppIcons.video),
          RoundButton(icon: AppIcons.video),
          BlocSelector<AvchatBloc, AvchatState, bool>(
            selector: (state) {
              return (state is AvchatMicBtnState) && state.isMuted;
            },
            builder: (context, isMuted) {
              if (isMuted) {
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
          ),
          RoundButton(
            icon: AppIcons.call_end,
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            onPressed: () {
              context.read<AvchatBloc>().add(AvchatEndCallBtnPressed());
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }
}
