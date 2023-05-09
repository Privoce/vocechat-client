import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/services/file_handler/channel_avatar_handler.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';

class VoceChannelAvatar extends StatefulWidget {
  // General variables for all constructors
  final double size;
  final bool isCircle;

  final bool? _isDefaultPublicChannel;

  final GroupInfoM? groupInfoM;

  final Uint8List? avatarBytes;

  final String? name;

  final bool enableServerRetry;

  /// Builds a ChannelAvatar with GroupInfoM
  ///
  /// Widget will show letter avatar if avatarBytes are not available
  VoceChannelAvatar.channel(
      {Key? key,
      required GroupInfoM this.groupInfoM,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableServerRetry = true})
      : name = groupInfoM.groupInfo.name,
        _isDefaultPublicChannel = groupInfoM.isPublic,
        avatarBytes = null,
        super(key: key);

  const VoceChannelAvatar.bytes(
      {Key? key,
      required Uint8List this.avatarBytes,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableServerRetry = true})
      : groupInfoM = null,
        name = null,
        _isDefaultPublicChannel = null,
        super(key: key);

  const VoceChannelAvatar.name(
      {Key? key,
      required String this.name,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableServerRetry = true})
      : groupInfoM = null,
        _isDefaultPublicChannel = null,
        avatarBytes = null,
        super(key: key);

  const VoceChannelAvatar.defaultPublicChannel(
      {Key? key, required this.size, this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        enableServerRetry = false,
        name = null,
        _isDefaultPublicChannel = true,
        avatarBytes = null,
        super(key: key);

  const VoceChannelAvatar.defaultPrivateChannel(
      {Key? key, required this.size, this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        enableServerRetry = false,
        name = null,
        _isDefaultPublicChannel = false,
        avatarBytes = null,
        super(key: key);

  @override
  State<VoceChannelAvatar> createState() => _VoceChannelAvatarState();
}

class _VoceChannelAvatarState extends State<VoceChannelAvatar> {
  @override
  void initState() {
    super.initState();
    App.app.chatService.subscribeGroups(_onChannelChanged);
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeGroups(_onChannelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupInfoM != null &&
        widget.groupInfoM!.groupInfo.avatarUpdatedAt != 0) {
      return FutureBuilder<File?>(
          future: ChannelAvatarHander().readOrFetch(widget.groupInfoM!,
              enableServerRetry: widget.enableServerRetry),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return VoceAvatar.file(
                  file: snapshot.data!,
                  size: widget.size,
                  isCircle: widget.isCircle);
            } else {
              return _buildNonFileAvatar();
            }
          });
    } else {
      return _buildNonFileAvatar();
    }
  }

  Widget _buildNonFileAvatar() {
    if (widget.avatarBytes != null && widget.avatarBytes!.isNotEmpty) {
      return VoceAvatar.bytes(
          avatarBytes: widget.avatarBytes!,
          size: widget.size,
          isCircle: widget.isCircle);
    } else if (widget.name != null && widget.name!.isNotEmpty) {
      return VoceAvatar.name(
          name: widget.name!, size: widget.size, isCircle: widget.isCircle);
    } else if (widget._isDefaultPublicChannel ?? false) {
      return VoceAvatar.icon(
          icon: AppIcons.channel, size: widget.size, isCircle: widget.isCircle);
    } else {
      return VoceAvatar.icon(
          icon: AppIcons.private_channel,
          size: widget.size,
          isCircle: widget.isCircle);
    }
  }

  Future<void> _onChannelChanged(
      GroupInfoM groupInfoM, EventActions action) async {
    if (groupInfoM.gid == widget.groupInfoM?.gid) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}
