import 'package:flutter/material.dart';
import 'package:vocechat_client/feature/avchat/model/avchat_user.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

class AvchatUserAudioTile extends StatefulWidget {
  const AvchatUserAudioTile({Key? key, required this.user}) : super(key: key);

  final AvchatUser user;

  @override
  State<AvchatUserAudioTile> createState() => _AvchatUserAudioTileState();
}

class _AvchatUserAudioTileState extends State<AvchatUserAudioTile> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Opacity(
        opacity: widget.user.connectState == AvchatUserConnectionState.connected
            ? 1
            : 0.6,
        child: _buildWidget(screenWidth));
  }

  Container _buildWidget(double screenWidth) {
    return Container(
      width: screenWidth / 2 - 16,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.grey.shade600, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Stack(
            children: [
              VoceUserAvatar.user(
                  userInfoM: widget.user.userInfoM,
                  size: 80,
                  enableOnlineStatus: false),
              _buildAudioStatus()
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.userInfoM.userInfo.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioStatus() {
    if (!widget.user.muted) {
      return SizedBox.shrink();
    }
    return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(AppIcons.mic_off, size: 18)));
  }
}
