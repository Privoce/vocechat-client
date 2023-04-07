import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/services/file_handler/channel_avatar_handler.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';

class VoceChannelAvatar extends StatelessWidget {
  // General variables for all constructors
  final double size;
  final bool isCircle;

  final bool? _isDefaultPublicChannel;

  final GroupInfoM? groupInfoM;

  final Uint8List? avatarBytes;

  final String? name;

  /// Builds a ChannelAvatar with GroupInfoM
  ///
  /// Widget will show letter avatar if avatarBytes are not available
  VoceChannelAvatar.channel(
      {Key? key,
      required GroupInfoM this.groupInfoM,
      required this.size,
      this.isCircle = useCircleAvatar})
      : name = groupInfoM.groupInfo.name,
        _isDefaultPublicChannel = groupInfoM.isPublic == 1,
        avatarBytes = null,
        super(key: key);

  const VoceChannelAvatar.bytes(
      {Key? key,
      required Uint8List this.avatarBytes,
      required this.size,
      this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        name = null,
        _isDefaultPublicChannel = null,
        super(key: key);

  const VoceChannelAvatar.name(
      {Key? key,
      required String this.name,
      required this.size,
      this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        _isDefaultPublicChannel = null,
        avatarBytes = null,
        super(key: key);

  const VoceChannelAvatar.defaultPublicChannel(
      {Key? key, required this.size, this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        name = null,
        _isDefaultPublicChannel = true,
        avatarBytes = null,
        super(key: key);

  const VoceChannelAvatar.defaultPrivateChannel(
      {Key? key, required this.size, this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        name = null,
        _isDefaultPublicChannel = false,
        avatarBytes = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (groupInfoM != null && groupInfoM!.groupInfo.avatarUpdatedAt != 0) {
      return FutureBuilder<File?>(
          future: ChannelAvatarHander().readOrFetch(groupInfoM!.gid),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return VoceAvatar.file(
                  file: snapshot.data!, size: size, isCircle: isCircle);
            } else {
              return _buildNonFileAvatar();
            }
          });
    } else {
      return _buildNonFileAvatar();
    }
  }

  Widget _buildNonFileAvatar() {
    if (avatarBytes != null && avatarBytes!.isNotEmpty) {
      return VoceAvatar.bytes(
          avatarBytes: avatarBytes!, size: size, isCircle: isCircle);
    } else if (name != null && name!.isNotEmpty) {
      return VoceAvatar.name(name: name!, size: size, isCircle: isCircle);
    } else if (_isDefaultPublicChannel ?? false) {
      return VoceAvatar.icon(
          icon: AppIcons.channel, size: size, isCircle: isCircle);
    } else {
      return VoceAvatar.icon(
          icon: AppIcons.private_channel, size: size, isCircle: isCircle);
    }
  }
}
