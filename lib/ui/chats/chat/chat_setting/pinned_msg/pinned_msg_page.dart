import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vocechat_client/api/lib/group_api.dart';

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/pinned_msg/pinned_msg_tile.dart';
import 'package:vocechat_client/ui/widgets/empty_content_placeholder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PinnedMsgPage extends StatelessWidget {
  final ValueNotifier<GroupInfoM> groupInfoMNotifier;

  PinnedMsgPage(this.groupInfoMNotifier);

  @override
  Widget build(BuildContext pageContext) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(pageContext)!.pin,
            style: Theme.of(pageContext).textTheme.headline6),
        centerTitle: true,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(pageContext);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
      ),
      body: SafeArea(
          child: ValueListenableBuilder<GroupInfoM>(
              valueListenable: groupInfoMNotifier,
              builder: (context, groupInfoM, _) {
                final pinnedMsgs = groupInfoM.groupInfo.pinnedMessages;
                if (pinnedMsgs.isEmpty) {
                  return EmptyContentPlaceholder(
                      text: AppLocalizations.of(context)!
                          .pinnedMsgPageEmptyChannelDes);
                }

                return ListView.builder(
                    itemCount: pinnedMsgs.length,
                    itemBuilder: (listViewContext, index) {
                      final msg = pinnedMsgs[index];
                      return FutureBuilder<UserInfoM?>(
                          future: UserInfoDao().getUserByUid(msg.createdBy),
                          builder: (futureContext, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    left: 8, top: 8, right: 8),
                                child: Container(
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white),
                                  child: Slidable(
                                    endActionPane: ActionPane(
                                        extentRatio: 0.3,
                                        motion: DrawerMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed: (context) {
                                              _onTapUnpin(
                                                  listViewContext, msg.mid);
                                            },
                                            icon: AppIcons.delete,
                                            label: AppLocalizations.of(context)!
                                                .unpin,
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          )
                                        ]),
                                    child: PinnedMsgTile(
                                        gid: groupInfoMNotifier.value.gid,
                                        msg: msg,
                                        userInfoM: snapshot.data!),
                                  ),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          });
                    });
              })),
    );
  }

  void _onTapUnpin(BuildContext context, int mid) {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.pinnedMsgPageUnPinTitle,
        content: AppLocalizations.of(context)!.pinnedMsgPageUnPinContent,
        primaryAction: AppAlertDialogAction(
          text: AppLocalizations.of(context)!.unpin,
          action: () async {
            Navigator.of(context).pop();
            final res = await _unPin(mid);
            if (res) {
              return;
            } else {
              showAppAlert(
                  context: context,
                  title: AppLocalizations.of(context)!
                      .pinnedMsgPageUnPinErrorTitle,
                  content: AppLocalizations.of(context)!
                      .pinnedMsgPageUnPinErrorContent,
                  actions: [
                    AppAlertDialogAction(
                        text: AppLocalizations.of(context)!.ok,
                        action: () => Navigator.of(context).pop())
                  ]);
            }
          },
        ),
        actions: [
          AppAlertDialogAction(
            text: AppLocalizations.of(context)!.cancel,
            action: () {
              Navigator.of(context).pop();
            },
          )
        ]);
  }

  Future<bool> _unPin(int mid) async {
    try {
      final groupApi = GroupApi();
      final res = await groupApi.pin(groupInfoMNotifier.value.gid, mid, false);
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }
}
