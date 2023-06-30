import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/api/models/group/group_update_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/app_textfield.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_channel_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';

class ChannelInfoPage extends StatefulWidget {
  final ValueNotifier<GroupInfoM> groupInfoNotifier;

  ChannelInfoPage(this.groupInfoNotifier);

  @override
  State<ChannelInfoPage> createState() => _ChannelInfoPageState();
}

class _ChannelInfoPageState extends State<ChannelInfoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ValueNotifier<bool> _doneBtnNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _uploadNotifier = ValueNotifier(false);

  late final GroupInfo _groupInfo;
  late bool _nameChanged;
  late bool _descriptionChanged;

  @override
  void initState() {
    super.initState();
    _groupInfo = widget.groupInfoNotifier.value.groupInfo;
    _nameController.text = _groupInfo.name;
    _descriptionController.text = _groupInfo.description ?? "";

    _nameChanged = false;
    _descriptionChanged = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          toolbarHeight: barHeight,
          elevation: 0,
          backgroundColor: AppColors.barBg,
          leading: CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
          actions: [
            ValueListenableBuilder<bool>(
                valueListenable: _doneBtnNotifier,
                builder: (context, enableBtn, _) {
                  if (enableBtn) {
                    return CupertinoButton(
                        onPressed: onDone,
                        child: Text(AppLocalizations.of(context)!.done,
                            style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 17,
                                color: AppColors.primaryBlue)));
                  }

                  return SizedBox.shrink();
                })
          ],
        ),
        body: SafeArea(
            child: ListView(
          children: [
            _buildAvatar(),
            SizedBox(height: 8),
            _buildTextFields(),
          ],
        )));
  }

  Widget _buildAvatar() {
    return AvatarInfoTile(
      avatar: ValueListenableBuilder<GroupInfoM>(
          valueListenable: widget.groupInfoNotifier,
          builder: (context, groupInfoM, _) {
            // return ChannelAvatar(
            //     avatarSize: VoceAvatarSize.s84,
            //     isPublic: _groupInfo.isPublic,
            //     avatarBytes: groupInfoM.avatar);
            return VoceChannelAvatar.channel(
                groupInfoM: groupInfoM, size: VoceAvatarSize.s84);
          }),
      title: _groupInfo.name,
      subtitleWidget: ValueListenableBuilder<bool>(
          valueListenable: _uploadNotifier,
          builder: (context, isUploading, _) {
            if (isUploading) {
              return CupertinoActivityIndicator();
            }
            return GestureDetector(
              onTap: _changeAvatar,
              child: Text(AppLocalizations.of(context)!.setNewAvatar,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: AppColors.primaryBlue)),
            );
          }),
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        AppTextField(
          header: AppLocalizations.of(context)!.name,
          controller: _nameController,
          textInputAction: TextInputAction.next,
          maxLength: 32,
          onChanged: (text) {
            if (text.trim() == _groupInfo.name) {
              _nameChanged = false;
            } else {
              _nameChanged = true;
            }

            _doneBtnNotifier.value = _nameChanged || _descriptionChanged;
          },
        ),
        SizedBox(height: 8),
        AppTextField(
          header: AppLocalizations.of(context)!.description,
          textInputAction: TextInputAction.done,
          maxLines: 5,
          maxLength: 128,
          controller: _descriptionController,
          onChanged: (text) {
            if (text.trim() == _groupInfo.description ||
                (text.trim().isEmpty && _groupInfo.description == null)) {
              _descriptionChanged = false;
            } else {
              _descriptionChanged = true;
            }

            _doneBtnNotifier.value = _nameChanged || _descriptionChanged;
          },
        ),
        SizedBox(height: 8),
      ],
    );
  }

  void _changeAvatar() async {
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _uploadNotifier.value = true;
      Uint8List bytes = await image.readAsBytes();
      bytes = await FlutterImageCompress.compressWithList(bytes, quality: 25);
      final groupApi = GroupApi();
      final res = await groupApi.uploadGroupAvatar(
          widget.groupInfoNotifier.value.gid, bytes);
      if (res.statusCode == 200) {
        App.logger.info("Group Avatar changed.");
        _uploadNotifier.value = false;
        return;
      } else if (res.statusCode == 413) {
        App.logger.severe("Payload too large");
        await showAppAlert(
            context: context,
            title: AppLocalizations.of(context)!.uploadError,
            content: AppLocalizations.of(context)!.uploadErrorContent,
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(context)!.ok,
                  action: () => Navigator.pop(context))
            ]);
        _uploadNotifier.value = false;
        return;
      }
    } else {
      _uploadNotifier.value = false;
      return;
    }
  }

  void onDone() async {
    String name = _nameController.text;
    String? des = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;

    final req = GroupUpdateRequest(name: name, description: des);

    try {
      final groupApi = GroupApi();
      final res =
          await groupApi.updateGroup(widget.groupInfoNotifier.value.gid, req);
      if (res.statusCode == 200) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }
}
