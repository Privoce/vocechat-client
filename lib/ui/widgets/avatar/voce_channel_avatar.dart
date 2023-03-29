import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';

class VoceChannelAvatar extends StatelessWidget {
  /// All channels are private by default.
  final GroupInfoM groupInfoM;
  final bool _useCircle;
  // final Widget Function()

  final double? cornerRadius;

  const VoceChannelAvatar.circle({Key? key, required this.groupInfoM})
      : _useCircle = true,
        cornerRadius = null,
        super(key: key);

  const VoceChannelAvatar.rect({Key? key, required this.groupInfoM})
      : _useCircle = false,
        cornerRadius = 8,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_useCircle) {
      return VoceAvatar.circle(
          avatarBytes: groupInfoM.avatar, name: groupInfoM.groupInfo.name);
    } else {
      return VoceAvatar.rect(
          avatarBytes: groupInfoM.avatar,
          name: groupInfoM.groupInfo.name,
          cornerRadius: cornerRadius);
    }
  }
}
