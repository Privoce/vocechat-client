// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:vocechat_client/api/models/msg/chat_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_normal.dart';
import 'package:vocechat_client/api/models/msg/msg_reaction.dart';
import 'package:vocechat_client/api/models/msg/msg_reply.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/reaction.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/init_dao/user_settings.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/task_queue.dart';
// import 'package:vocechat_client/globals.dart' as globals;

// enum MsgType {text, markdown, image, file}

// ignore: must_be_immutable
class ChatMsgM extends Equatable with M {
  int mid = -1;
  String localMid = "";
  int fromUid = -1;
  int dmUid = -1;
  int gid = -1;
  // int _edited = 0;
  String statusStr =
      MsgStatus.success.name; // MsgStatus: fail, success, sending
  String detail = ""; // only normal msg json.
  // String _reactions = ""; // ChatMsgReactions
  int pin = 0;

  // Following not included in db
  ReactionData? reactionData;

  set status(MsgStatus status) {
    statusStr = status.name;
  }

  MsgStatus get status {
    switch (statusStr) {
      case "success":
        return MsgStatus.success;
      case "fail":
        return MsgStatus.fail;
      case "readyToSend":
        return MsgStatus.readyToSend;
      case "sending":
        return MsgStatus.sending;
      case "deleted":
        return MsgStatus.deleted;
      default:
        return MsgStatus.success;
    }
  }

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

  // Set<ReactionInfo> get reactions {
  //   if (_reactions.isEmpty) {
  //     return {};
  //   }
  //   Iterable l = json.decode(_reactions);
  //   return Set<ReactionInfo>.from(l.map((e) => ReactionInfo.fromJson(e)));
  // }

  bool get shouldShowProgressWhenSending {
    return isFileMsg || isAudioMsg;
  }

  bool get pinned {
    return pin != 0;
  }

  // bool get edited {
  //   return _edited != 0;
  // }

  bool get isGroupMsg {
    return dmUid == -1 && gid != -1;
  }

  bool get isNormalMsg {
    return detailType == MsgDetailType.normal;
  }

  bool get isReplyMsg {
    return detailType == MsgDetailType.reply;
  }

  bool get isReactionMsg {
    return detailType == MsgDetailType.reaction;
  }

  bool get isEditReactionMsg {
    return isReactionMsg && msgReaction?.type == "edit";
  }

  bool get isDeleteReactionMsg {
    return isReactionMsg && msgReaction?.type == "delete";
  }

  /// normal, reaction and reply.
  String get detailTypeStr {
    return json.decode(detail)["type"] ?? "";
  }

  MsgDetailType? get detailType {
    if (detail.isEmpty) return null;
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

  bool get isTextMsg {
    try {
      final type = json.decode(detail)["content_type"] as String?;
      return type == typeText;
    } catch (e) {
      return false;
    }
  }

  bool get isMarkdownMsg {
    try {
      final type = json.decode(detail)["content_type"] as String?;
      return type == typeMarkdown;
    } catch (e) {
      return false;
    }
  }

  /// Check whether a message is of type vocechat/file
  ///
  /// Includes all files, includes images and file. Audio, archives are not included.
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

  bool get isGifImageMsg {
    try {
      final type = json.decode(detail)["properties"]["content_type"] as String?;
      return type?.toLowerCase() == 'image/gif';
    } catch (e) {
      return false;
    }
  }

  bool get isAudioMsg {
    try {
      final type = json.decode(detail)["content_type"] as String?;
      return type == typeAudio;
    } catch (e) {
      return false;
    }
  }

  bool get isArchiveMsg {
    try {
      final type = json.decode(detail)["content_type"] as String?;
      return type == typeArchive;
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

  bool get expired {
    try {
      final expiresIn = json.decode(detail)["expires_in"];
      if (expiresIn != null && expiresIn != 0) {
        return createdAt + expiresIn * 1000 <
            DateTime.now().millisecondsSinceEpoch;
      }
    } catch (e) {}
    return false;
  }

  Future<bool> get needDeleting async {
    try {
      bool deleted = false;

      final reactions = await ReactionDao().getReactions(mid);
      if (reactions?.isDeleted == true) {
        deleted = true;
      }

      return deleted;
    } catch (e) {}
    return false;
  }

  Future<bool> get expiredOrNeedsDeleting async {
    return expired || (await needDeleting);
  }

  /// text/plain, text/markdown, vocechat/file, vocechat/archive
  /// in msgNormal.detail
  String get detailContentTypeStr {
    return json.decode(detail)["content_type"] ?? "";
  }

  /// MIME
  /// in msgNormal.detail.properties
  String get fileContentTypeStr {
    return json.decode(detail)["properties"]["content_type"] ?? "";
  }

  MsgContentType? get detailContentType {
    switch (json.decode(detail)["content_type"]) {
      case typeText:
        return MsgContentType.text;
      case typeMarkdown:
        return MsgContentType.markdown;
      case typeFile:
        return MsgContentType.file;
      case typeArchive:
        return MsgContentType.archive;
      case typeAudio:
        return MsgContentType.audio;
      default:
        return null;
    }
  }

  ChatMsgM();

  ChatMsgM.item(
      String id,
      this.mid,
      this.localMid,
      this.fromUid,
      this.dmUid,
      this.gid,
      // this._edited,
      this.statusStr,
      int createdAt,
      this.detail,
      // this._reactions,
      this.pin) {
    super.id = id;
    super.createdAt = createdAt;
  }

  ChatMsgM.fromMsg(ChatMsg chatMsg, this.localMid, MsgStatus status) {
    // id = chatMsg.mid.toString();
    id = localMid;
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

    statusStr = status.name;
    createdAt = chatMsg.createdAt;
  }

  ChatMsgM.fromOld(ChatMsgM old) {
    id = old.id;
    mid = old.mid;
    localMid = old.localMid;
    fromUid = old.fromUid;
    dmUid = old.dmUid;
    gid = old.dmUid;
    statusStr = old.statusStr;
    createdAt = old.createdAt;
    detail = old.detail;
    pin = old.pin;
  }

  ChatMsgM.fromReply(ChatMsg chatMsg, this.localMid, MsgStatus status) {
    id = chatMsg.mid.toString();
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

    statusStr = status.name;
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
    if (map.containsKey(F_status)) {
      m.statusStr = map[F_status];
    }
    if (map.containsKey(F_detail)) {
      m.detail = map[F_detail];
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
  static const F_id = 'id';
  static const F_mid = 'mid';
  static const F_localMid = 'local_mid';
  static const F_fromUid = 'from_uid';
  static const F_dmUid = 'dm_uid';
  static const F_gid = 'gid';
  static const F_status = 'status';
  static const F_detail = 'detail';
  static const F_pin = 'pin';
  static const F_createdAt = 'created_at';

  @override
  Map<String, Object> get values => {
        ChatMsgM.F_id: id,
        ChatMsgM.F_mid: mid,
        ChatMsgM.F_localMid: localMid,
        ChatMsgM.F_fromUid: fromUid,
        ChatMsgM.F_dmUid: dmUid,
        ChatMsgM.F_gid: gid,
        ChatMsgM.F_status: statusStr,
        ChatMsgM.F_detail: detail,
        ChatMsgM.F_pin: pin,
        ChatMsgM.F_createdAt: createdAt,
      };

  static MMeta meta = MMeta.fromType(ChatMsgM, ChatMsgM.fromMap)
    ..tableName = F_tableName;

  @override
  List<Object?> get props => [
        mid,
        localMid,
        fromUid,
        dmUid,
        gid,
        statusStr,
        detail,
        pin,
        createdAt,
        reactionData
      ];
}

class ChatMsgDao extends Dao<ChatMsgM> {
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

    final reactionData = await ReactionDao().getReactions(m.mid);

    return m..reactionData = reactionData;
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
      ChatMsgM msgM, MsgStatus status) async {
    ChatMsgM? old = await first(
        where: '${ChatMsgM.F_localMid} = ?', whereArgs: [msgM.localMid]);
    if (old != null) {
      msgM = old;
      msgM.statusStr = status.name;
      await super.update(msgM);
      App.logger.info(
          "Chat Msg status updated. mid: ${msgM.mid}, localMid: ${msgM.localMid}, status: $status");
      return true;
    }
    return false;
  }

  Future<ChatMsgM?> pinMsgByMid(int mid, int uid) async {
    try {
      final sqlstr = 'UPDATE ${ChatMsgM.F_tableName} SET ${ChatMsgM.F_pin} = '
          '$uid WHERE ${ChatMsgM.F_mid} = $mid RETURNING *';
      List<Map<String, dynamic>> result = await db.rawQuery(sqlstr);
      final newMsgM = ChatMsgM.fromMap(result.first);
      final reactionData = await ReactionDao().getReactions(mid);
      return newMsgM..reactionData = reactionData;
    } catch (e) {
      App.logger.severe(e);
      return null;
    }
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

  /// Get the minimum mid in a channel.
  ///
  /// Include mid of messages, and also mid of reactions.
  Future<int?> getChannelMinMid(int gid) async {
    String sqlStr =
        'SELECT MIN(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid} = $gid';
    List<Map<String, Object?>> msgRecords = await db.rawQuery(sqlStr);

    int minMid = double.maxFinite.toInt();
    if (msgRecords.isNotEmpty &&
        msgRecords.first["MIN(${ChatMsgM.F_mid})"] != null) {
      minMid = min(minMid, msgRecords.first["MIN(${ChatMsgM.F_mid})"] as int);
    }

    sqlStr =
        'SELECT MIN(${ReactionM.F_mid}) FROM ${ReactionM.F_tableName} WHERE ${ReactionM.F_targetGid} = $gid';
    List<Map<String, Object?>> reactionRecords = await db.rawQuery(sqlStr);
    if (reactionRecords.isNotEmpty &&
        reactionRecords.first["MIN(${ReactionM.F_mid})"] != null) {
      minMid =
          min(minMid, reactionRecords.first["MIN(${ReactionM.F_mid})"] as int);
    }

    if (minMid < double.maxFinite.toInt() && minMid > 0) {
      return minMid;
    }
    return null;
  }

  Future<ChatMsgM?> getMsgByMid(int mid, {bool withReactions = true}) async {
    final msg =
        await super.first(where: "${ChatMsgM.F_mid} = ?", whereArgs: [mid]);
    if (withReactions && msg != null) {
      final reactionData = await ReactionDao().getReactions(mid);
      msg.reactionData = reactionData;
    }
    return msg;
  }

  Future<List<ChatMsgM>?> getPreImageMsgBeforeMid(int mid,
      {int? limit, int? uid, int? gid, bool withReactions = false}) async {
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
      final msgList = <ChatMsgM>[];
      for (final each in records) {
        final msgM = ChatMsgM.fromMap(each);
        if (!(await msgM.expiredOrNeedsDeleting)) {
          msgList.add(msgM);
        }
      }

      if (withReactions) {
        final dao = ReactionDao();
        for (var each in msgList) {
          final reactionData = await dao.getReactions(each.mid);
          each.reactionData = reactionData;
        }
      }

      return msgList;
    }
    return null;
  }

  Future<List<ChatMsgM>?> getNextImageMsgAfterMid(int mid,
      {int? limit, int? uid, int? gid, bool withReactions = false}) async {
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
      final msgList = <ChatMsgM>[];
      for (final each in records) {
        final msgM = ChatMsgM.fromMap(each);
        if (!(await msgM.expiredOrNeedsDeleting)) {
          msgList.add(msgM);
        }
      }

      if (withReactions) {
        final dao = ReactionDao();
        for (var each in msgList) {
          final reactionData = await dao.getReactions(each.mid);
          each.reactionData = reactionData;
        }
      }

      return msgList;
    }
    return null;
  }

  Future<ChatMsgM?> getMsgBylocalMid(String localMid,
      {bool withReactions = false}) async {
    final msg = await super
        .first(where: "${ChatMsgM.F_localMid} = ?", whereArgs: [localMid]);

    if (withReactions && msg != null) {
      final reactionData = await ReactionDao().getReactions(msg.mid);
      msg.reactionData = reactionData;
    }

    return msg;
  }

  /// Get the max message id in App, including 'deleted' messages.
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
    final dmSettings = await UserSettingsDao().getDmSettings(dmUid);
    if (dmSettings == null) return -1;

    final readIndex = dmSettings.readIndex;

    String sqlStr =
        'SELECT COUNT(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid} = $dmUid AND ${ChatMsgM.F_mid}>$readIndex AND ${ChatMsgM.F_fromUid}!=${App.app.userDb!.uid}';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final count = records.first["COUNT(${ChatMsgM.F_mid})"];
      if (count != null) {
        return count as int;
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
    final groupSettings = await UserSettingsDao().getGroupSettings(gid);
    if (groupSettings == null) return -1;

    final readIndex = groupSettings.readIndex;

    String sqlStr =
        'SELECT COUNT(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid}=$gid AND ${ChatMsgM.F_mid}>$readIndex AND ${ChatMsgM.F_fromUid}!=${App.app.userDb!.uid}';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final count = records.first["COUNT(${ChatMsgM.F_mid})"];
      if (count != null) {
        return count as int;
      }
    }

    return -1;
  }

  /// Returns a future of the number of messages in which myself was mentioned.'
  /// If there are multiple mentions inside one message, only count as mentioned once.
  Future<int> getGroupUnreadMentionCount(int gid) async {
    try {
      final groupSettings = await UserSettingsDao().getGroupSettings(gid);
      if (groupSettings == null) return -1;

      final readIndex = groupSettings.readIndex;

      int count = 0;

      String sqlStr =
          'SELECT * FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid}=$gid AND ${ChatMsgM.F_mid}>$readIndex AND ${ChatMsgM.F_fromUid}!=${App.app.userDb!.uid}';

      List<Map<String, dynamic>> records = await db.rawQuery(sqlStr);
      if (records.isNotEmpty) {
        for (var record in records) {
          final recordJson = record["detail"];
          if (recordJson != null) {
            final mentions = json.decode(recordJson)["properties"]?["mentions"];

            if (mentions != null && mentions.contains(App.app.userDb!.uid)) {
              count += 1;
              continue;
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

  Future<ChatMsgM?> getDmLatestMsgM(int uid,
      {bool withReactions = false}) async {
    String sqlStr =
        'SELECT * FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid} = $uid AND ${ChatMsgM.F_mid} = (SELECT MAX(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_dmUid} = $uid)';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final msg = ChatMsgM.fromMap(records.first);
      if (withReactions) {
        msg.reactionData = await ReactionDao().getReactions(msg.mid);
      }
      return msg;
    }
    return null;
  }

  Future<ChatMsgM?> getChannelLatestMsgM(int gid,
      {bool withReactions = false}) async {
    String sqlStr =
        'SELECT * FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid} = $gid AND ${ChatMsgM.F_mid} = (SELECT MAX(${ChatMsgM.F_mid}) FROM ${ChatMsgM.F_tableName} WHERE ${ChatMsgM.F_gid} = $gid)';
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final msg = ChatMsgM.fromMap(records.first);
      if (withReactions) {
        msg.reactionData = await ReactionDao().getReactions(msg.mid);
      }
      return msg;
    }
    return null;
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

  Future<int> deleteMsgByMsg(ChatMsgM m) async {
    // m is the notification msg, targetMid is the real msg to be deleted.
    final int targetMid = m.mid;

    return deleteMsgByMid(targetMid);
  }

  /// Set a [ChatMsgM] object with empty detail and [MsgStatus.deleted] status.
  ///
  /// Returns the [mid] of the deleted message.
  /// Returns -1 if the message could not be found.
  Future<int> deleteMsgByMid(int targetMid) async {
    final deleteCount = await db.delete(ChatMsgM.F_tableName,
        where: "${ChatMsgM.F_mid} = ?", whereArgs: [targetMid]);
    // final updateCount = await db.update(ChatMsgM.F_tableName,
    //     {ChatMsgM.F_detail: "", ChatMsgM.F_status: MsgStatus.deleted},
    //     where: "${ChatMsgM.F_mid} = ?",
    //     whereArgs: [targetMid],
    //     conflictAlgorithm: ConflictAlgorithm.replace);
    App.logger.info("Msg deleted. Mid: $targetMid");

    if (deleteCount == 0) {
      // the original message could not be found.
      return -1;
    }

    return targetMid;
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

  Future<void> clearChatMsgTable() async {
    try {
      await db.delete(ChatMsgM.F_tableName);
      App.logger.info("ChatMsg table cleared.");
    } catch (e) {
      App.logger.severe(e);
    }
  }

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
      PageMeta pageMeta, String orderBy, int gid,
      {bool withReactions = false}) async {
    final msgs = await paginateLast(pageMeta, orderBy,
        where: '${ChatMsgM.F_gid} = ?', whereArgs: [gid]);

    if (withReactions) {
      final reactionDao = ReactionDao();
      for (var msg in msgs.records) {
        msg.reactionData = await reactionDao.getReactions(msg.mid);
      }
    }

    return msgs;
  }

  Future<PageData<ChatMsgM>> paginateLastByDmUid(
      PageMeta pageMeta, String orderBy, int dmUid,
      {bool withReactions = false}) async {
    final msgs = await paginateLast(pageMeta, orderBy,
        where: '${ChatMsgM.F_dmUid} = ?', whereArgs: [dmUid]);

    if (withReactions) {
      final reactionDao = ReactionDao();
      for (var msg in msgs.records) {
        msg.reactionData = await reactionDao.getReactions(msg.mid);
      }
    }

    return msgs;
  }
}
