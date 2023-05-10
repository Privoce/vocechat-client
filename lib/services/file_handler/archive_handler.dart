import 'dart:convert';

import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/archive.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';

class ArchiveHandler {
  Future<ArchiveM?> getLocalArchive(ChatMsgM chatMsgM) async {
    final archiveId = chatMsgM.msgNormal!.content;
    final archiveM = await ArchiveDao().getArchive(archiveId);
    if (archiveM != null) {
      return archiveM;
    }
    return null;
  }

  Future<ArchiveM?> getArchive(ChatMsgM chatMsgM,
      {bool serverFetch = true}) async {
    final archiveId = chatMsgM.msgNormal!.content;
    final archiveM = await ArchiveDao().getArchive(archiveId);
    if (archiveM != null) {
      return archiveM;
    }

    if (serverFetch) {
      try {
        final resourceApi = ResourceApi();
        final res = await resourceApi.getArchive(archiveId);
        if (res.statusCode == 200 && res.data != null) {
          final archive = res.data!;
          final archiveM = ArchiveM.item(
              archiveId, json.encode(archive), chatMsgM.createdAt);

          await ArchiveDao().addOrUpdate(archiveM);
          return archiveM;
        } else {
          App.logger.severe("Archive fetched failed. Id: $archiveId");
        }
      } catch (e) {
        App.logger.severe("$e, archiveId: $archiveId");
      }
    }
    return null;
  }
}
