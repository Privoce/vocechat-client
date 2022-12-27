import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chats/server_account_data.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerAccountTile extends StatefulWidget {
  final ValueNotifier<ServerAccountData> accountData;
  final VoidCallback? onLogoutTapped;

  const ServerAccountTile(
      {Key? key, required this.accountData, this.onLogoutTapped})
      : super(key: key);

  @override
  State<ServerAccountTile> createState() => _ServerAccountTileState();
}

class _ServerAccountTileState extends State<ServerAccountTile> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ServerAccountData>(
        valueListenable: widget.accountData,
        builder: (context, account, _) {
          return Container(
              color: account.selected ? AppColors.cyan100 : Colors.white,
              padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
              child: Row(
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatar(account.serverAvatarBytes,
                            account.userAvatarBytes, account.username),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildInfo(
                              account.serverName,
                              account.serverUrl,
                              account.username,
                              account.userEmail),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                  if (widget.onLogoutTapped != null) _buildMore()
                ],
              ));
        });
  }

  Widget _buildAvatar(
      Uint8List serverAvatarBytes, Uint8List userAvatarBytes, String username) {
    final serverAvatar = CircleAvatar(
        foregroundImage: MemoryImage(serverAvatarBytes),
        backgroundColor: Colors.white,
        radius: 24);
    final userAvatar = UserAvatar(
        avatarSize: AvatarSize.s36,
        uid: -1,
        name: username,
        avatarBytes: userAvatarBytes);

    return SizedBox(
      height: 66,
      width: 66,
      child: Stack(children: [
        Positioned(top: 0, left: 0, child: serverAvatar),
        Positioned(right: 0, bottom: 0, child: userAvatar)
      ]),
    );
  }

  Widget _buildInfo(
      String serverName, String serverUrl, String username, String userEmail) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(serverName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleLarge),
      Text(serverUrl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall),
      Padding(
          padding: EdgeInsets.only(left: 0, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium),
              Text(userEmail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall)
            ],
          ))
    ]);
  }

  Widget _buildMore() {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: SizedBox(width: 32, height: 32, child: Icon(Icons.more_horiz)),
        onPressed: () {
          // logout
          showCupertinoModalPopup(
              context: context,
              builder: (context) {
                return CupertinoActionSheet(
                  actions: [
                    CupertinoActionSheetAction(
                        onPressed: () {
                          showAppAlert(
                            context: context,
                            title: AppLocalizations.of(context)!.logOut,
                            content:
                                "${AppLocalizations.of(context)!.serverAccountLogoutWarning} \"${widget.accountData.value.serverName}\"?",
                            actions: [
                              AppAlertDialogAction(
                                  text: AppLocalizations.of(context)!.cancel,
                                  action: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  }),
                            ],
                            primaryAction: AppAlertDialogAction(
                                text: AppLocalizations.of(context)!.logOut,
                                action: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  _onTapLogOut();
                                },
                                isDangerAction: true),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.logOut,
                          style: TextStyle(color: AppColors.systemRed),
                        )),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.cancel)),
                );
              });
        });
  }

  Future<void> _onTapLogOut() async {
    if (widget.onLogoutTapped != null) {
      widget.onLogoutTapped!();
    }
  }
}
