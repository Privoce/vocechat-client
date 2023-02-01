import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/app_textfield.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerInfoSettingsPage extends StatefulWidget {
  @override
  State<ServerInfoSettingsPage> createState() => _ServerInfoSettingsPageState();
}

class _ServerInfoSettingsPageState extends State<ServerInfoSettingsPage> {
  final ValueNotifier<bool> _doneBtnNotifier = ValueNotifier(false);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _desController = TextEditingController();

  late final ChatServerM chatServerM;

  late bool _isAdmin;
  bool _nameEdited = false;
  bool _descriptionEdited = false;

  @override
  void initState() {
    chatServerM = App.app.chatServerM;

    super.initState();
    _nameController.text = chatServerM.properties.serverName;
    _desController.text = chatServerM.properties.description ?? "";

    _isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: barHeight,
        backgroundColor: AppColors.barBg,
        title: Text(
          AppLocalizations.of(context)!.serverInfoSettingTitle,
          style: AppTextStyles.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        actions: [
          ValueListenableBuilder<bool>(
              valueListenable: _doneBtnNotifier,
              builder: (context, enableBtn, _) {
                if (!_isAdmin) {
                  return SizedBox.shrink();
                }
                if (enableBtn) {
                  return CupertinoButton(
                      onPressed: onDone,
                      child: Text(AppLocalizations.of(context)!.done));
                }
                return CupertinoButton(
                    onPressed: null,
                    child: Text(AppLocalizations.of(context)!.done));
              })
        ],
      ),
      body: SafeArea(
          child: ListView(
        children: [
          AvatarInfoTile(
            avatar: UserAvatar(
              uid: -1,
              avatarSize: AvatarSize.s84,
              name: chatServerM.properties.serverName,
              avatarBytes: chatServerM.logo,
            ),
            titleWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _isAdmin
                    ? GestureDetector(
                        onTap: _changeAvatar,
                        child: Text(AppLocalizations.of(context)!.setNewAvatar,
                            style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                                color: AppColors.primary400)),
                      )
                    : SizedBox.shrink()),
          ),
          AppTextField(
            enabled: _isAdmin,
            header: AppLocalizations.of(context)!.serverInfoSettingNameHint,
            textInputAction: TextInputAction.next,
            maxLines: 1,
            maxLength: 32,
            controller: _nameController,
            onChanged: (text) {
              if (text.trim() == chatServerM.properties.serverName) {
                _nameEdited = false;
              } else {
                _nameEdited = true;
              }

              _doneBtnNotifier.value = _nameEdited || _descriptionEdited;
            },
          ),
          SizedBox(height: 8),
          AppTextField(
            enabled: _isAdmin,
            maxLines: 5,
            maxLength: 128,
            header: AppLocalizations.of(context)!.serverInfoSettingDesHint,
            textInputAction: TextInputAction.done,
            controller: _desController,
            onChanged: (text) {
              if (text.trim() == chatServerM.properties.description) {
                _descriptionEdited = false;
              } else {
                _descriptionEdited = true;
              }

              _doneBtnNotifier.value = _nameEdited || _descriptionEdited;
            },
            footer: AppLocalizations.of(context)!.serverInfoSettingFooter,
          )
        ],
      )),
    );

    // return
  }

  void _changeAvatar() async {
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final res =
          await App.app.authService!.adminSystemApi.uploadOrgLogo(bytes);
      if (res.statusCode == 200) {
        return;
      } else if (res.statusCode == 413) {
        App.logger.severe("Payload too large");
        // TODO: show alerts.
        return;
      }
    } else {
      return;
    }
  }

  void onDone() async {
    String name = _nameController.text;
    String? des = _desController.text.isEmpty ? null : _desController.text;

    try {
      final res = await App.app.authService!.adminSystemApi
          .setOrgInfo(name: name, description: des);
      if (res.statusCode == 200) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }
}
