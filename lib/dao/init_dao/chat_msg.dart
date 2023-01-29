// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:vocechat_client/api/models/msg/chat_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_normal.dart';
import 'package:vocechat_client/api/models/msg/msg_reaction.dart';
import 'package:vocechat_client/api/models/msg/msg_reply.dart';
import 'package:vocechat_client/api/models/msg/msg_target_group.dart';
import 'package:vocechat_client/api/models/msg/msg_target_user.dart';
import 'package:vocechat_client/api/models/msg/reaction_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/unmatched_reaction.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/task_queue.dart';

// enum MsgType {text, markdown, image, file}

class ChatMsgM with M {
  int mid = -1;
  String localMid = "";
  int fromUid = -1;
  int dmUid = -1;
  int gid = -1;
  int edited = 0;
  String status =
      MsgSendStatus.success.name; // MsgStatus: fail, success, sending
  String detail = ""; // only normal msg json.
  String _reactions = ""; // ChatMsgReactions
  int pin = 0;

  MsgNormal? get msgNormal {
    if (detail.isNotEmpty && json.decode(detail)['type'] == 'normal') {
      return MsgNormal.fromJson(json.decode(detail));
    }
    return null;
  }

  MsgReaction? get msgReaction {
    if (detail.isNotEmpty && json.decode(detail)['type'] == 'reaction') {
      return MsgReaction.fromJson(json.decode(detail));
    }
    return null;
  }

  MsgReply? get msgReply {
    if (detail.isNotEmpty && json.decode(detail)['type'] == 'reply') {
      return MsgReply.fromJson(json.decode(detail));
    }
    return null;
  }

  Set<ReactionInfo> get reactions {
    if (_reactions.isEmpty) {
      return {};
    }
    Iterable l = json.decode(_reactions);
    return Set<ReactionInfo>.from(l.map((e) => ReactionInfo.fromJson(e)));
  }

  // int get serverCreatedAt {
  //   return
  // }

  bool get isGroupMsg {
    return dmUid == -1 && gid != -1;
  }

  /// normal, reaction and reply.
  String get typeStr {
    return json.decode(detail)["type"] ?? "";
  }

  MsgDetailType? get type {
    switch (json.decode(detail)["type"]) {
      case "normal":
        return MsgDetailType.normal;
      case "reaction":
        return MsgDetailType.reaction;
      case "reply":
        return MsgDetailType.reply;
      default:
        return null;
    }
  }

  /// text/plain, text/markdown, vocechat/file, vocechat/archive
  /// in msgNormal.detail
  String get detailContentType {
    return json.decode(detail)["content_type"] ?? "";
  }

  /// MIME
  /// in msgNormal.detail.properties
  String get fileContentType {
    return json.decode(detail)["properties"]["content_type"] ?? "";
  }

  MsgContentType? get detailType {
    switch (json.decode(detail)["content_type"]) {
      case typeText:
        return MsgContentType.text;
      case typeMarkdown:
        return MsgContentType.markdown;
      case typeFile:
        return MsgContentType.file;
      case typeArchive:
        return MsgContentType.archive;
      default:
        return null;
    }
  }

  bool get isFileMsg {
    try {
      final type = json.decode(detail)["content_type"] as String?;
      return type == typeFile;
    } catch (e) {
      return false;
    }
  }

  bool get isImageMsg {
    try {
      final type = json.decode(detail)["properties"]["content_type"] as String?;
      return type?.split("/").first.toLowerCase() == 'image';
    } catch (e) {
      return false;
    }
  }

  bool get isVideoMsg {
    try {
      final type = json.decode(detail)["properties"]["content_type"] as String?;
      return type?.split("/").first.toLowerCase() == 'video';
    } catch (e) {
      return false;
    }
  }

  bool get hasMention {
    try {
      return detail.isNotEmpty &&
          json.decode(detail)['properties']['mentions'] != null &&
          (json.decode(detail)['properties']['mentions'] as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  bool get expires {
    try {
      final expiresIn = json.decode(detail)["expires_in"];
      if (expiresIn != null && expiresIn != 0) {
        return createdAt + expiresIn * 1000 <
            DateTime.now().millisecondsSinceEpoch;
      }
    } catch (e) {}
    return false;
  }

  ChatMsgM();

  ChatMsgM.item(
      this.mid,
      this.localMid,
      this.fromUid,
      this.dmUid,
      this.gid,
      this.edited,
      this.status,
      createdAt,
      this.detail,
      this._reactions,
      this.pin) {
    super.createdAt = createdAt;
  }

  ChatMsgM.fromMsg(ChatMsg chatMsg, this.localMid, MsgSendStatus status) {
    mid = chatMsg.mid;
    fromUid = chatMsg.fromUid;

    detail = json.encode(chatMsg.detail);

    if (chatMsg.target.containsKey("uid")) {
      if (fromUid == App.app.userDb!.uid) {
        dmUid = chatMsg.target["uid"];
      } else {
        dmUid = fromUid;
      }
    } else {
      dmUid = -1;
    }

    gid = chatMsg.target["gid"] ?? -1;

    this.status = status.name;
    createdAt = chatMsg.createdAt;
  }

  ChatMsgM.fromOld(ChatMsgM old) {
    mid = old.mid;
    localMid = old.localMid;
    fromUid = old.fromUid;
    dmUid = old.dmUid;
    gid = old.dmUid;
    edited = old.edited;
    status = old.status;
    createdAt = old.createdAt;
    detail = old.detail;
    _reactions = old._reactions;
    pin = old.pin;
  }

  ChatMsgM.fromDeleted(ChatMsg chatMsg, this.localMid) {
    mid = chatMsg.mid;
    fromUid = chatMsg.fromUid;
    detail = json.encode(chatMsg.detail);
    if (chatMsg.target.containsKey("uid")) {
      if (fromUid == App.app.userDb!.uid) {
        dmUid = chatMsg.target["uid"];
      } else {
        dmUid = fromUid;
      }
    } else {
      dmUid = -1;
    }
    gid = chatMsg.target["gid"] ?? -1;
    createdAt = chatMsg.createdAt;
  }

  ChatMsgM.fromReply(ChatMsg chatMsg, this.localMid, MsgSendStatus status) {
    mid = chatMsg.mid;
    fromUid = chatMsg.fromUid;
    detail = json.encode(chatMsg.detail);
    if (chatMsg.target.containsKey("uid")) {
      if (fromUid == App.app.userDb!.uid) {
        dmUid = chatMsg.target["uid"];
      } else {
        dmUid = fromUid;
      }
    } else {
      dmUid = -1;
    }
    gid = chatMsg.target["gid"] ?? -1;

    this.status = status.name;
    createdAt = chatMsg.createdAt;
  }

  static ChatMsgM fromMap(Map<String, dynamic> map) {
    ChatMsgM m = ChatMsgM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_mid)) {
      m.mid = map[F_mid];
    }
    if (map.containsKey(F_localMid)) {
      m.localMid = map[F_localMid];
    }
    if (map.containsKey(F_fromUid)) {
      m.fromUid = map[F_fromUid];
    }
    if (map.containsKey(F_dmUid)) {
      m.dmUid = map[F_dmUid];
    }
    if (map.containsKey(F_gid)) {
      m.gid = map[F_gid];
    }
    if (map.containsKey(F_edited)) {
      m.edited = map[F_edited];
    }

    if (map.containsKey(F_status)) {
      m.status = map[F_status];
    }
    if (map.containsKey(F_detail)) {
      m.detail = map[F_detail];
    }
    if (map.containsKey(F_reactions)) {
      m._reactions = map[F_reactions];
    }
    if (map.containsKey(F_pin)) {
      m.pin = map[F_pin];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }

    return m;
  }

  static const F_tableName = 'chat_msg';
  static const F_mid = 'mid';
  static const F_localMid = 'local_mid';
  static const F_fromUid = 'from_uid';
  static const F_dmUid = 'dm_uid';
  static const F_gid = 'gid';
  static const F_edited = 'edited';
  static const F_status = 'status';
  static const F_detail = 'detail';
  static const F_reactions = 'reactions';
  static const F_pin = 'pin';
  static const F_createdAt = 'created_at';

  @override
  Map<String, Object> get values => {
        ChatMsgM.F_mid: mid,
        ChatMsgM.F_localMid: localMid,
        ChatMsgM.F_fromUid: fromUid,
        ChatMsgM.F_dmUid: dmUid,
        ChatMsgM.F_gid: gid,
        ChatMsgM.F_edited: edited,
        ChatMsgM.F_status: status,
        ChatMsgM.F_detail: detail,
        ChatMsgM.F_reactions: _reactions,
        ChatMsgM.F_pin: pin,
        ChatMsgM.F_createdAt: createdAt,
      };

  static MMeta meta = MMeta.fromType(ChatMsgM, ChatMsgM.fromMap)
    ..tableName = F_tableName;
}

class ChatMsgDao extends Dao<ChatMsgM> {
  final Set<int> unmatchedReactionSet = {};

  TaskQueue taskQueue = TaskQueue();

  ChatMsgDao() {
    ChatMsgM.meta;
  }

  Future<ChatMsgM> addOrUpdate(ChatMsgM m) async {
    ChatMsgM? old = await first(
        where: '${ChatMsgM.F_localMid} = ?', whereArgs: [m.localMid]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = max(old.createdAt, m.createdAt);

      await super.update(m);
      App.logger.info("Chat Msg updated. m: ${m.values}");
    } else {
      await super.add(m);
      App.logger.info("Chat Msg added. m: ${m.values}");
    }

    if (m.mid > 0 && unmatchedReactionSet.contains(m.mid)) {
      final unmatchedReactions =
          await UnmatchedReactionDao().getUnmatchedReactions(m.mid);
      if (unmatchedReactions != null) {
        TaskQueue q = TaskQueue(enableStatusDisplay: false);
        final rs = unmatchedReactions.reactionList as List<String>;
        for (var r in rs) {
          final reactionInfo = ReactionInfo.fromJson(jsonDecode(r));
          q.add(() {
            return reactMsgByMid(m.mid, reactionInfo.fromUid,
                reactionInfo.reaction, reactionInfo.createdAt);
          });
        }
        UnmatchedReactionDao().deleteReactions(m.mid);
        unmatchedReactionSet.remove(m.mid);
      }
    }

    return m;
  }

  Future<ChatMsgM> addOrUpdateByMid(ChatMsgM m) async {
    ChatMsgM? old =
        await first(where: '${ChatMsgM.F_mid} = ?', whereArgs: [m.mid]);
    if (old != null) {
      m.id = old.id;
      m.localMid = old.localMid;
      m.createdAt = old.createdAt;
      await super.update(m);
    } else {
      await super.add(m);
    }
    App.logger.info("Chat Msg saved. m: ${m.values}");
    return m;
  }

  Future<bool> updateMsgByLocalMid(ChatMsgM msgM) async {
    ChatMsgM? old = await first(
        where: '${ChatMsgM.F_localMid} = ?', whereArgs: [msgM.localMid]);
    if (old != null) {
      msgM.id = old.id;
      msgM.createdAt = old.createdAt;
      await super.update(msgM);
      App.logger.info(
          "Chat Msg Updated. mid: ${msgM.mid}, localMid: ${msgM.localMid}");
      return true;
    }
    return false;
  }

  Future<bool> updateMsgStatusByLocalMid(
      ChatMsgM msgM, MsgSendStatus status) async {
    ChatMsgM? old = await first(
        where: '${ChatMsgM.F_localMid} = ?', whereArgs: [msgM.localMid]);
    if (old != null) {
      msgM = old;
      msgM.status = status.name;
      await super.update(msgM);
      App.logger.info(
          "Chat Msg status updated. mid: ${msgM.mid}, localMid: ${msgM.localMid}, status: $status");
      return true;
    }
    return false;
  }

  Future<ChatMsgM?> editMsgByMid(
      int mid, String newContent, MsgSendStatus status) async {
    ChatMsgM? old =
        await first(where: '${ChatMsgM.F_mid} = ?', whereArgs: [mid]);
    if (old != null) {
      Map oldDetail = json.decode(old.detail);
      oldDetail["content"] = newContent;
      old.detail = json.encode(oldDetail);
      old.edited = 1;
      old.status = status.name;

      await super.update(old);
      App.logger.info("ChatMsg Edit Updated. msg: ${old.values}");
      return old;
    }
    return null;
  }

  Future<ChatMsgM?> pinMsgByMid(int mid) async {
    ChatMsgM? old =
        await first(where: '${ChatMsgM.F_mid} = ?', whereArgs: [mid]);
    if (old != null) {
      old.pin = 1;
      await super.update(old);
      App.logger.info("ChatMsg Edit Updated. msg: ${old.values}");
      return old;
    }
    return null;
  }

  Future<ChatMsgM?> reactMsgByMid(
      int mid, int fromUid, String reaction, int time) async {
    ChatMsgM? old =
        await first(where: '${ChatMsgM.F_mid} = ?', whereArgs: [mid]);
    if (old != null) {
      var reactions = old.reactions;

      final r = ReactionInfo(fromUid, reaction, time);

      if (reactions.contains(r)) {
        reactions.remove(r);
      } else {
        reactions.add(r);
      }

      final reactionList = reactions.map((e) => json.encode(e)).toList();
      old._reactions = reactions.isEmpty ? "" : "$reactionList";
      await super.update(old);
      App.logger.info(
          "ChatMsg Reactions Updated. mid: ${old.mid}, localMid: ${old.localMid}");
      return old;
    } else {
      final r = jsonEncode(ReactionInfo(fromUid, reaction, time));
      unmatchedReactionSet.add(mid);
      UnmatchedReactionDao().addReaction(mid, r);
    }

    return null;
  }

  /// Get a list of DM messages by dmUid (uid).
  ///
  /// Result ordered by localMid, ascending order.
  Future<List<ChatMsgM>?> getDmMsgListByDmUid(int dmUid) async {
    return super.query(
        where: "${ChatMsgM.F_dmUid} = ?",
        whereArgs: [dmUid],
        orderBy: "${ChatMsgM.F_mid} ASC");
  }

  /// Get a list of DM messages by dmUid (uid).
  ///
  /// Result ordered by createdAt, ascending order.
  Future<List<ChatMsgM>?> getAllDmMsgList() async {
    return super.query(
        where: "${ChatMsgM.F_gid} = ?",
        whereArgs: [-1],
        orderBy: "${ChatMsgM.F_mid} ASC");
  }

  /// Get a list of group messages by group Id (gid).
  ///
  /// Result ordered by localMid, ascending order.
  Future<List<ChatMsgM>?> getGroupMsgListByGid(int gid) async {
    return super.query(
        where: "${ChatMsgM.F_gid} = ?",
        whereArgs: [gid],
        orderBy: "${ChatMsgM.F_mid} ASC");
  }

  /// Get the number of messages in a chat using gid for channels and uid for dms.
  Future<int> getChatMsgCount({int? gid, int? uid}) async {
    assert((gid != null && uid == null) || (gid == null && uid != null));
    String sqlStr;

    if (gid != null) {
      sqlStr =
          'SELECT COUNT(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid} = $gid';
    } else {
      sqlStr =
          'SELECT COUNT(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid} = $uid';
    }
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final count = records.first["COUNT(${ChatMsgM.F_mid})"];
      if (count != null) {
        return count as int;
      }
    }
    return 0;
  }

  Future<int> getMinMidInChannel(int gid) async {
    String sqlStr =
        'SELECT MIN(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid} = $gid';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final maxMid = records.first["MIN(${ChatMsgM.F_mid})"];
      if (maxMid != null) {
        return maxMid as int;
      }
    }
    return -1;
  }

  Future<ChatMsgM?> getMsgByMid(int mid) async {
    return super.first(where: "${ChatMsgM.F_mid} = ?", whereArgs: [mid]);
  }

  Future<List<ChatMsgM>?> getPreImageMsgBeforeMid(int mid,
      {int? limit, int? uid, int? gid}) async {
    String chatIdStr = "";
    if (uid != null && uid >= 0) {
      chatIdStr = "${ChatMsgM.F_dmUid} = $uid";
    } else if (gid != null && gid >= 0) {
      chatIdStr = "${ChatMsgM.F_gid} = $gid";
    }

    String sqlStr =
        "SELECT * FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_mid} < $mid AND $chatIdStr AND json_extract(${ChatMsgM.F_detail}, '\$.properties.content_type') LIKE 'image/%' ORDER BY ${ChatMsgM.F_mid} DESC ${limit != null ? "LIMIT $limit" : ""}";
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);

    if (records.isNotEmpty) {
      final msgList = records
          .map((e) {
            final msgM = ChatMsgM.fromMap(e);
            if (!msgM.expires) {
              return msgM;
            }
          })
          .toList()
          .whereType<ChatMsgM>()
          .toList();

      return msgList;
    }
    return null;
  }

  Future<List<ChatMsgM>?> getNextImageMsgAfterMid(int mid,
      {int? limit, int? uid, int? gid}) async {
    String chatIdStr = "";
    if (uid != null && uid >= 0) {
      chatIdStr = "${ChatMsgM.F_dmUid} = $uid";
    } else if (gid != null && gid >= 0) {
      chatIdStr = "${ChatMsgM.F_gid} = $gid";
    }
    String sqlStr =
        "SELECT * FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_mid} > $mid AND $chatIdStr AND json_extract(${ChatMsgM.F_detail}, '\$.properties.content_type') LIKE 'image/%' ORDER BY ${ChatMsgM.F_mid} ASC ${limit != null ? "LIMIT $limit" : ""}";
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);

    if (records.isNotEmpty) {
      final msgList = records
          .map((e) {
            final msgM = ChatMsgM.fromMap(e);
            if (!msgM.expires) {
              return msgM;
            }
          })
          .toList()
          .whereType<ChatMsgM>()
          .toList();

      return msgList;
    }
    return null;
  }

  Future<ChatMsgM?> getMsgBylocalMid(String localMid) async {
    return super
        .first(where: "${ChatMsgM.F_localMid} = ?", whereArgs: [localMid]);
  }

  /// Get the max message id in App.
  ///
  /// Returns -1 if there is no message in database.
  Future<int> getMaxMid() async {
    String sqlStr =
        'SELECT MAX(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName}';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final maxMid = records.first["MAX(${ChatMsgM.F_mid})"];
      if (maxMid != null) {
        return maxMid as int;
      }
    }
    return -1;
  }

  Future<int> getDmMaxMid(int dmUid) async {
    String sqlStr =
        'SELECT MAX(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid}=$dmUid';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final maxMid = records.first["MAX(${ChatMsgM.F_mid})"];
      if (maxMid != null) {
        return maxMid as int;
      }
    }
    return -1;
  }

  Future<int> getDmUnreadCount(int dmUid) async {
    final readIndex =
        (await UserInfoDao().getUserByUid(dmUid))?.properties.readIndex;
    if (readIndex != null) {
      String sqlStr =
          'SELECT COUNT(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid} = $dmUid AND ${ChatMsgM.F_mid}>$readIndex AND ${ChatMsgM.F_fromUid}!=${App.app.userDb!.uid}';
      List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
      if (records.isNotEmpty) {
        final count = records.first["COUNT(${ChatMsgM.F_mid})"];
        if (count != null) {
          return count as int;
        }
      }
    }
    return -1;
  }

  Future<int> getChannelMaxMid(int gid) async {
    String sqlStr =
        'SELECT MAX(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid}=$gid';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final maxMid = records.first["MAX(${ChatMsgM.F_mid})"];
      if (maxMid != null) {
        return maxMid as int;
      }
    }
    return -1;
  }

  Future<int> getGroupUnreadCount(int gid) async {
    final readIndex =
        (await GroupInfoDao().getGroupByGid(gid))?.properties.readIndex;
    if (readIndex != null) {
      String sqlStr =
          'SELECT COUNT(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid}=$gid AND ${ChatMsgM.F_mid}>$readIndex AND ${ChatMsgM.F_fromUid}!=${App.app.userDb!.uid}';
      List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
      if (records.isNotEmpty) {
        final count = records.first["COUNT(${ChatMsgM.F_mid})"];
        if (count != null) {
          return count as int;
        }
      }
    }
    return -1;
  }

  /// Returns a future of the number of messages in which myself was mentioned.'
  /// If there are multiple mentions inside one message, only count as mentioned once.
  Future<int> getGroupUnreadMentionCount(int gid) async {
    try {
      final readIndex =
          (await GroupInfoDao().getGroupByGid(gid))?.properties.readIndex;
      // print(readIndex);
      int count = 0;
      if (readIndex != null) {
        // String sqlStr =
        //     'SELECT json_extract(${ChatMsgM.F_detail}, "\$.properties.mentions") AS detail FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid}=$gid AND ${ChatMsgM.F_mid}>$readIndex AND ${ChatMsgM.F_fromUid}!=${App.app.userDb!.uid}';
        String sqlStr =
            'SELECT * FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid}=$gid AND ${ChatMsgM.F_mid}>$readIndex AND ${ChatMsgM.F_fromUid}!=${App.app.userDb!.uid}';

        List<Map<String, dynamic>> records = await db.rawQuery(sqlStr);
        if (records.isNotEmpty) {
          for (var record in records) {
            final recordJson = record["detail"];
            if (recordJson != null) {
              final mentions =
                  json.decode(recordJson)["properties"]?["mentions"];

              if (mentions != null && mentions.contains(App.app.userDb!.uid)) {
                count += 1;
                continue;
              }
            }
          }
        }
      }
      return count;
    } catch (e) {
      App.logger.severe(e);
    }
    return 0;
  }

  Future<String> getLatestLocalMidInGroup(int gid) async {
    String sqlStr =
        'SELECT MAX(${ChatMsgM.F_createdAt}), ${ChatMsgM.F_localMid} FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid} = $gid';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final latestLocalMid = records.first[ChatMsgM.F_localMid];
      if (latestLocalMid != null) {
        return latestLocalMid as String;
      }
    }
    return "";
  }

  Future<int> getLatestMidInGroup(int gid) async {
    String sqlStr =
        'SELECT MAX(${ChatMsgM.F_createdAt}), ${ChatMsgM.F_mid} FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid} = $gid';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final latestMid = records.first[ChatMsgM.F_mid];
      if (latestMid != null) {
        return latestMid as int;
      }
    }
    return -1;
  }

  Future<String> getLatestLocalMidInDm(int uid) async {
    String sqlStr =
        'SELECT MAX(${ChatMsgM.F_createdAt}), ${ChatMsgM.F_localMid} FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid} = $uid';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final latestLocalMid = records.first[ChatMsgM.F_localMid];
      if (latestLocalMid != null) {
        return latestLocalMid as String;
      }
    }
    return "";
  }

  /// Get the message id of the latest message in this DM.
  ///
  /// returns -1 if no message in DM.
  Future<int> getLatestMidInDm(int uid) async {
    String sqlStr =
        'SELECT MAX(${ChatMsgM.F_createdAt}), ${ChatMsgM.F_mid} FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid} = $uid';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final latestMid = records.first[ChatMsgM.F_mid];
      if (latestMid != null) {
        return latestMid as int;
      }
    }
    return -1;
  }

  Future<int> deleteMsgByMid(ChatMsgM m) async {
    // m is the notification msg, targetMid is the real msg to be deleted.
    final int? targetMid = m.mid;

    if (targetMid != null) {
      await db.delete(ChatMsgM.F_tableName,
          where: "${ChatMsgM.F_mid} = ?", whereArgs: [targetMid]);
      App.logger.info("Msg deleted. Mid: $targetMid");
    } else {
      App.logger.info("Msg not exist. mid: ${m.mid}");
    }
    return targetMid ?? -1;
  }

  Future<bool> deleteMsgByLocalMid(ChatMsgM m) async {
    // m is the notification msg, targetMid is the real msg to be deleted.
    final targetLocalMid = m.localMid;

    try {
      await db.delete(ChatMsgM.F_tableName,
          where: "${ChatMsgM.F_localMid} = ?", whereArgs: [targetLocalMid]);
      App.logger.info("Msg deleted. localMid: ${m.localMid}");
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
    return true;
  }

  Future<int> deleteMsgByUid(int dmUid) async {
    try {
      return await db.delete(ChatMsgM.F_tableName,
          where: "${ChatMsgM.F_dmUid} = ?", whereArgs: [dmUid]).then((value) {
        App.logger.info("Messages in Dm $dmUid have been deleted.");
        return value;
      });
    } catch (e) {
      App.logger.severe(e);
      return -1;
    }
  }

  Future<int> deleteMsgByGid(int gid) async {
    try {
      return await db.delete(ChatMsgM.F_tableName,
          where: "${ChatMsgM.F_gid} = ?", whereArgs: [gid]).then((value) {
        App.logger.info("Messages in Channel $gid have been deleted.");
        return value;
      });
    } catch (e) {
      App.logger.severe(e);
      return -1;
    }
  }
  // Future<ChatMsgM> deleteMsgByMid(ChatMsgM m) async {
  //   final targetMid = json.decode(m.detail)["mid"];
  //   if (targetMid == null) {
  //     await super.add(m);
  //     App.logger
  //         .info("Deleted Msg Added. mid: ${m.mid}, localMid: ${m.localMid}");
  //     return m;
  //   }

  //   ChatMsgM? old =
  //       await first(where: '${ChatMsgM.F_mid} = ?', whereArgs: [targetMid]);
  //   if (old != null) {
  //     old.status = MsgStatus.success.name;
  //     old.detail = m.detail;
  //     old._reactions = "";
  //     old.info = "";
  //     old._type = MsgType.deleted.name;

  //     await super.update(old);
  //     App.logger
  //         .info("Chat Msg removed. mid: ${old.mid}, localMid: ${old.localMid}");
  //     return old;
  //   } else {
  //     await super.add(m);
  //     App.logger
  //         .info("Deleted Msg Added. mid: ${m.mid}, localMid: ${m.localMid}");
  //     return m;
  //   }
  // }

  @override
  Future<PageData<ChatMsgM>> paginate(PageMeta pageMeta,
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    orderBy ??= '${ChatMsgM.F_mid} ASC';
    return await super.paginate(pageMeta,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  @override
  Future<PageData<ChatMsgM>> paginateLast(PageMeta pageMeta, String orderBy,
      {String? where, List<Object?>? whereArgs}) async {
    String order = orderBy.isNotEmpty ? orderBy : '${ChatMsgM.F_mid} ASC';
    return await super
        .paginateLast(pageMeta, order, where: where, whereArgs: whereArgs);
  }

  Future<PageData<ChatMsgM>> paginateLastByGid(
      PageMeta pageMeta, String orderBy, int gid) async {
    return await paginateLast(pageMeta, orderBy,
        where: '${ChatMsgM.F_gid} = ?', whereArgs: [gid]);
  }

  Future<PageData<ChatMsgM>> paginateLastByDmUid(
      PageMeta pageMeta, String orderBy, int dmUid) async {
    return await paginateLast(pageMeta, orderBy,
        where: '${ChatMsgM.F_dmUid} = ?', whereArgs: [dmUid]);
  }
}
