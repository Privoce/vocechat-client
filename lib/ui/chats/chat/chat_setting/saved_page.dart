import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vocechat_client/api/lib/saved_api.dart';
import 'package:vocechat_client/api/models/saved/saved_response.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/saved.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/saved_bubble.dart';
import 'package:vocechat_client/ui/widgets/empty_content_placeholder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SavedItemPage extends StatefulWidget {
  final int? gid;
  final int? uid;

  SavedItemPage({this.gid, this.uid}) {
    assert((gid != null && uid == null) || (gid == null && uid != null));
  }

  @override
  State<SavedItemPage> createState() => _SavedItemPageState();
}

class _SavedItemPageState extends State<SavedItemPage> {
  final SavedApi _savedApi = SavedApi(App.app.chatServerM.fullUrl);

  List<SavedM> savedList = [];
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    _refreshSavedList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(AppLocalizations.of(context)!.savedItems,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge),
            ),
            ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, _) {
                  if (loading) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child:
                          CupertinoActivityIndicator(color: AppColors.grey500),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }),
          ],
        ),
        centerTitle: true,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
      ),
      body: SafeArea(
          child: savedList.isEmpty
              ? EmptyContentPlaceholder(
                  text: widget.gid == null
                      ? AppLocalizations.of(context)!.savedItemEmptyChatDes
                      : AppLocalizations.of(context)!.savedItemEmptyChannelDes)
              : ListView.builder(
                  itemCount: savedList.length,
                  itemBuilder: (context, index) {
                    final archive = savedList[index].saved;
                    final filePath = savedList[index].id;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
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
                                      _onTapDelete(filePath);
                                    },
                                    icon: AppIcons.delete,
                                    label: "Delete",
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  )
                                ]),
                            child: SavedBubble(
                                archive: archive,
                                filePath: filePath,
                                getSavedFiles: getSavedFiles)),
                      ),
                    );
                  })),
    );
  }

  void _onTapDelete(String id) async {
    showAppAlert(
        context: context,
        title: "Delete Saved Item",
        content: "Are you sure to delete this saved item?",
        primaryAction: AppAlertDialogAction(
          text: "Delete",
          isDangerAction: true,
          action: () async {
            final res = await _onDelete(id);
            if (res) {
              final idx = savedList.indexWhere((element) => element.id == id);
              if (idx != -1) {
                savedList.removeAt(idx);
              }
              Navigator.of(context).pop();
              setState(() {});
            }
          },
        ),
        actions: [
          AppAlertDialogAction(
              text: "Cancel",
              action: () {
                Navigator.of(context).pop();
              })
        ]);
  }

  Future<bool> _onDelete(String id) async {
    try {
      final res = await _savedApi.deleteSaved(id);
      if (res.statusCode == 200) {
        await SavedDao().remove(id);
        await FileHandler.singleton.deleteSavedItem(id);
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
      showAppAlert(
          context: context,
          title: "Delete Saved Item Error",
          content: "Something wrong with saved item deletion.",
          actions: [
            AppAlertDialogAction(
                text: "OK", action: () => Navigator.of(context).pop())
          ]);
    }
    return false;
  }

  // TODO: to be changed
  Future<File?> getSavedFiles(
      int uid, String archiveId, int attachmentId, bool download) async {
    return FileHandler.singleton
        .getSavedItemsFile(uid, archiveId, attachmentId);
    // final savedM = await SavedFileDao.dao.getSavedFile(filePath, attachmentId);
    // if (savedM != null && savedM.file.isNotEmpty) {
    //   return savedM.file;
    // }

    // final res = await _savedApi.getSavedAttachment(
    //     uid, filePath, attachmentId, download);
    // if (res.statusCode == 200 && res.data != null && res.data!.isNotEmpty) {
    //   final savedFileM =
    //       SavedFileM.item(filePath, attachmentId, res.data!, createdAt);

    //   try {
    //     final savedFile = await SavedFileDao.dao.addOrUpdate(savedFileM);
    //     return savedFile.file;
    //   } catch (e) {
    //     App.logger.severe(e);
    //   }
    // }
    // return null;
  }

  /// Only fetch locally saved messages.
  Future<void> _getLocalSavedList({int? gid, int? uid}) async {
    isLoading.value = true;

    if (gid != null) {
      final l = await SavedDao().getSavedListByChat(gid: gid);
      if (l != null) {
        savedList = l;
      }
    } else if (uid != null) {
      final l = await SavedDao().getSavedListByChat(uid: uid);
      if (l != null) {
        savedList = l;
      }
    }
    isLoading.value = false;
    setState(() {});
  }

  /// Fetch Ids and retrieve all saved archives.
  Future _refreshSavedList() async {
    await _getLocalSavedList(gid: widget.gid, uid: widget.uid);

    bool needsRefreshing = false;
    isLoading.value = true;
    try {
      final res = await _savedApi.listSaved();
      if (res.statusCode != 200 || res.data == null) {
        return null;
      }

      final serverSavedList =
          res.data!.map((e) => SavedResponse.fromJson(e)).toList();
      final serverIdList = serverSavedList.map((e) => e.id).toList();
      final existingIdList = await SavedDao().getSavedIdList();

      // Add to local db.
      for (var each in serverSavedList) {
        if (existingIdList.contains(each.id)) {
          continue;
        }

        needsRefreshing = true;
        final savedRes = await _savedApi.getSaved(each.id);
        if (savedRes.statusCode != 200 || savedRes.data == null) {
          continue;
        }

        final savedArchive = savedRes.data!;
        final savedM =
            SavedM.item(each.id, jsonEncode(savedArchive), each.createdAt, "");
        await SavedDao().addOrUpdate(savedM);
      }

      // Remove from local db.
      for (var id in existingIdList) {
        if (serverIdList.contains(id)) {
          continue;
        }

        needsRefreshing = true;

        await SavedDao().remove(id);
        await FileHandler.singleton.deleteSavedItem(id);
      }

      isLoading.value = false;

      if (needsRefreshing) {
        _getLocalSavedList(gid: widget.gid, uid: widget.uid);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    isLoading.value = false;
    return null;
  }
}
