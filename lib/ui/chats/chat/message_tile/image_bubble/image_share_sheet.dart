import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_gallery_page.dart';

class ImageShareSheet extends StatefulWidget {
  final ChatMsgM chatMsgM;

  ImageShareSheet({required this.chatMsgM});

  @override
  State<ImageShareSheet> createState() => _ImageShareSheetState();
}

class _ImageShareSheetState extends State<ImageShareSheet> {
  final ValueNotifier<ButtonStatus> _saveBtnStatus =
      ValueNotifier(ButtonStatus.normal);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey800,
      child: SafeArea(
        child: SizedBox(
          height: 241,
          child: Column(
            children: [
              _buildRecentChats(),
              Divider(color: AppColors.grey600, indent: 8, endIndent: 8),
              _buildButtons(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChats() {
    return SizedBox(
      height: 120,
      child: Row(
        children: [],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          _buildSaveButton(),
          CupertinoButton(
              padding: EdgeInsets.all(8),
              onPressed: () {},
              child: _buildButtonChild(
                  Icon(AppIcons.forward, size: 32, color: Colors.white),
                  AppLocalizations.of(context)!.forward)),
          CupertinoButton(
              padding: EdgeInsets.all(8),
              onPressed: _share,
              child: _buildButtonChild(
                  Icon(AppIcons.share, size: 32, color: Colors.white),
                  AppLocalizations.of(context)!.share))
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ValueListenableBuilder<ButtonStatus>(
        valueListenable: _saveBtnStatus,
        builder: (context, status, _) {
          Widget child;
          double size = 32;

          switch (status) {
            case ButtonStatus.normal:
              child = Icon(Icons.save_alt, color: Colors.white, size: size);
              break;
            case ButtonStatus.inProgress:
              child = CupertinoActivityIndicator(
                  radius: size / 2, color: Colors.white);
              break;
            case ButtonStatus.success:
              child = Icon(Icons.check, color: Colors.white, size: size);
              break;
            case ButtonStatus.error:
              child = Icon(CupertinoIcons.exclamationmark,
                  color: Colors.white, size: size);
              break;

            default:
              child = Icon(Icons.save_alt, color: Colors.white, size: size);
          }
          return CupertinoButton(
              padding: EdgeInsets.all(8),
              onPressed: status == ButtonStatus.normal ? _saveImage : null,
              child: _buildButtonChild(
                  child, AppLocalizations.of(context)!.save,
                  color: status == ButtonStatus.error
                      ? AppColors.errorRed
                      : AppColors.grey600));
        });
  }

  Widget _buildButtonChild(Widget child, String title, {Color? color}) {
    return Column(children: [
      Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color ?? AppColors.grey600),
          child: child),
      Text(title,
          style: AppTextStyles.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]);
  }

  void _saveImage() async {
    _saveBtnStatus.value = ButtonStatus.inProgress;

    try {
      final imageFile =
          await FileHandler.singleton.getLocalImage(widget.chatMsgM);
      if (imageFile != null) {
        final result = await ImageGallerySaver.saveFile(imageFile.path);
        if (result["isSuccess"]) {
          _saveBtnStatus.value = ButtonStatus.success;
          await Future.delayed(Duration(seconds: 2)).then((_) async {
            _saveBtnStatus.value = ButtonStatus.normal;
          });
          return;
        }
      }
    } catch (e) {
      App.logger.severe(e);
    }

    _saveBtnStatus.value = ButtonStatus.error;
    await Future.delayed(Duration(seconds: 2)).then((_) async {
      _saveBtnStatus.value = ButtonStatus.normal;
    });
    _saveBtnStatus.value = ButtonStatus.normal;
    return;
  }

  void _forwardImage() {}

  void _share() async {
    Navigator.of(context).pop();
    try {
      final imageFile =
          await FileHandler.singleton.getLocalImage(widget.chatMsgM);
      if (imageFile != null) {
        Share.shareFiles([imageFile.path]);
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }
}

class RecentChatData {
  final UserInfoM? userInfoM;
  final GroupInfoM? groupInfoM;

  RecentChatData({this.userInfoM, this.groupInfoM});
}
