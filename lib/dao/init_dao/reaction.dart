// ignore_for_file: constant_identifier_names

import 'package:equatable/equatable.dart';
import 'package:vocechat_client/api/models/msg/chat_msg.dart';
import 'package:vocechat_client/api/models/msg/reaction_info.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/dao.dart';

class ReactionM with M {
  int mid = -1;
  int targetMid = -1;
  int targetGid = -1;
  int targetUid = -1;
  int fromUid = -1;
  String actionEmoji = "";
  String editedText = "";
  String _type = "";

  @override
  // ignore: overridden_fields
  int createdAt = 0;

  MsgReactionType get type {
    if (_type == MsgReactionType.edit.name) {
      return MsgReactionType.edit;
    } else if (_type == MsgReactionType.delete.name) {
      return MsgReactionType.delete;
    } else if (_type == MsgReactionType.action.name) {
      return MsgReactionType.action;
    } else {
      return MsgReactionType.none;
    }
  }

  ReactionM();

  ReactionM.item({
    required this.mid,
    required this.targetMid,
    required this.targetGid,
    required this.targetUid,
    required this.fromUid,
    required this.actionEmoji,
    required this.editedText,
    required bool deleted,
    required MsgReactionType type,
    required this.createdAt,
  });

  ReactionM.edit({
    required this.mid,
    required this.targetMid,
    required this.targetGid,
    required this.targetUid,
    required this.fromUid,
    required this.editedText,
    required this.createdAt,
  }) : _type = MsgReactionType.edit.name;

  ReactionM.action({
    required this.mid,
    required this.targetMid,
    required this.targetGid,
    required this.targetUid,
    required this.fromUid,
    required this.actionEmoji,
    required this.createdAt,
  }) : _type = MsgReactionType.action.name;

  ReactionM.delete({
    required this.mid,
    required this.targetMid,
    required this.targetGid,
    required this.targetUid,
    required this.fromUid,
    required this.createdAt,
  }) : _type = MsgReactionType.delete.name;

  static ReactionM fromEdit(Map<String, dynamic> json) {
    return ReactionM.edit(
      mid: json['mid'],
      targetMid: json["detail"]?['mid'] ?? -1,
      targetGid: json['target']?['gid'] ?? -1,
      targetUid: json['target']?['uid'] ?? -1,
      fromUid: json['from_uid'],
      editedText: json['detail']?['detail']?['content'] ?? "",
      createdAt: json['created_at'],
    );
  }

  static ReactionM fromAction(Map<String, dynamic> json) {
    return ReactionM.action(
      mid: json['mid'],
      targetMid: json["detail"]?['mid'] ?? -1,
      targetGid: json['target']?['gid'] ?? -1,
      targetUid: json['target']?['uid'] ?? -1,
      fromUid: json['from_uid'],
      actionEmoji: json['detail']?['detail']?['action'] ?? "",
      createdAt: json['created_at'],
    );
  }

  static ReactionM fromDelete(Map<String, dynamic> json) {
    return ReactionM.delete(
      mid: json['mid'],
      targetMid: json["detail"]?['mid'] ?? -1,
      targetGid: json['target']?['gid'] ?? -1,
      targetUid: json['target']?['uid'] ?? -1,
      fromUid: json['from_uid'],
      createdAt: json['created_at'],
    );
  }

  static ReactionM? fromChatMsg(ChatMsg chatMsg) {
    int mid = chatMsg.mid;
    int targetMid = chatMsg.detail["mid"];
    int targetGid = chatMsg.target["gid"] ?? -1;
    int targetUid = chatMsg.target["uid"] ?? -1;
    int fromUid = chatMsg.fromUid;

    int createdAt = chatMsg.createdAt;
    switch (chatMsg.detail["detail"]["type"]) {
      case "edit":
        String editedText = chatMsg.detail["detail"]["content"] ?? "";
        return ReactionM.edit(
            mid: mid,
            targetMid: targetMid,
            targetGid: targetGid,
            targetUid: targetUid,
            fromUid: fromUid,
            editedText: editedText,
            createdAt: createdAt);

      case "like":
        String actionEmoji = chatMsg.detail["detail"]["action"] ?? "";
        return ReactionM.action(
            mid: mid,
            targetMid: targetMid,
            targetGid: targetGid,
            targetUid: targetUid,
            fromUid: fromUid,
            actionEmoji: actionEmoji,
            createdAt: createdAt);
      case "delete":
        return ReactionM.delete(
            mid: mid,
            targetMid: targetMid,
            targetGid: targetGid,
            targetUid: targetUid,
            fromUid: fromUid,
            createdAt: createdAt);
      default:
        return null;
    }
  }

  static ReactionM fromMap(Map<String, dynamic> map) {
    ReactionM m = ReactionM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_mid)) {
      m.mid = map[F_mid];
    }
    if (map.containsKey(F_targetMid)) {
      m.targetMid = map[F_targetMid];
    }
    if (map.containsKey(F_targetGid)) {
      m.targetGid = map[F_targetGid];
    }
    if (map.containsKey(F_targetUid)) {
      m.targetUid = map[F_targetUid];
    }
    if (map.containsKey(F_fromUid)) {
      m.fromUid = map[F_fromUid];
    }
    if (map.containsKey(F_actionEmoji)) {
      m.actionEmoji = map[F_actionEmoji];
    }
    if (map.containsKey(F_editedText)) {
      m.editedText = map[F_editedText];
    }
    if (map.containsKey(F_type)) {
      m._type = map[F_type];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }

    return m;
  }

  static const F_tableName = 'reactions';
  static const F_mid = 'mid';
  static const F_targetMid = 'target_mid';
  static const F_targetGid = 'target_gid';
  static const F_targetUid = 'target_uid';
  static const F_fromUid = 'from_uid';
  static const F_actionEmoji = 'action_emoji';
  static const F_editedText = 'edited_text';
  static const F_type = 'type';
  static const F_createdAt = 'created_at';

  @override
  Map<String, Object> get values => {
        ReactionM.F_mid: mid,
        ReactionM.F_targetMid: targetMid,
        ReactionM.F_targetGid: targetGid,
        ReactionM.F_targetUid: targetUid,
        ReactionM.F_fromUid: fromUid,
        ReactionM.F_actionEmoji: actionEmoji,
        ReactionM.F_editedText: editedText,
        ReactionM.F_type: _type,
        ReactionM.F_createdAt: createdAt
      };

  static MMeta meta = MMeta.fromType(ReactionM, ReactionM.fromMap)
    ..tableName = F_tableName;
}

class ReactionDao extends Dao<ReactionM> {
  ReactionDao() {
    ReactionM.meta;
  }

  Future<ReactionData?> getReactions(int mid) async {
    final reactions = await super
        .query(where: "${ReactionM.F_targetMid} = ?", whereArgs: [mid]);
    if (reactions.isEmpty) return null;

    Set<ReactionInfo> preliminaryReactionSet = {};
    String? editedText;
    for (var e in reactions) {
      if (e.type == MsgReactionType.action) {
        final reactionInfo = ReactionInfo(
            emoji: e.actionEmoji, fromUid: e.fromUid, createdAt: e.createdAt);

        if (preliminaryReactionSet.contains(reactionInfo)) {
          preliminaryReactionSet.remove(reactionInfo);
        } else {
          preliminaryReactionSet.add(reactionInfo);
        }
      } else if (e.type == MsgReactionType.edit) {
        editedText = e.editedText;
      } else if (e.type == MsgReactionType.delete) {
        await removeReaction(mid);
        return null;
      }
    }

    if (preliminaryReactionSet.isEmpty && editedText == null) {
      return null;
    } else {
      return ReactionData(
          reactionSet: preliminaryReactionSet, editedText: editedText);
    }
  }

  Future<int> removeReaction(int mid) async {
    return db.delete(ReactionM.F_tableName,
        where: "${ReactionM.F_targetMid} = ?", whereArgs: [mid]);
  }
}

// ignore: must_be_immutable
class ReactionData extends Equatable {
  Set<ReactionInfo>? reactionSet = {};

  String? editedText;

  Map<String, int> _reactionCountMap = {};

  void addReaction(ReactionInfo reaction) {
    reactionSet ??= {};
    if (reactionSet!.contains(reaction)) {
      reactionSet!.remove(reaction);
      if (reactionSet!.isEmpty) {
        reactionSet = null;
      }
    } else {
      reactionSet!.add(reaction);
    }
    updateReactionCountMap();
  }

  void updateReactionCountMap() {
    _reactionCountMap = {};
    if (reactionSet == null || reactionSet!.isEmpty) return;

    for (var reaction in reactionSet!) {
      if (_reactionCountMap.containsKey(reaction.emoji)) {
        _reactionCountMap[reaction.emoji] =
            _reactionCountMap[reaction.emoji]! + 1;
      } else {
        _reactionCountMap[reaction.emoji] = 1;
      }
    }
  }

  Map<String, int> get reactionCountMap => _reactionCountMap;
  bool get hasReaction => reactionSet != null && reactionSet!.isNotEmpty;
  bool get hasEditedText => editedText != null && editedText!.isNotEmpty;

  /// A comprehensive data model of reactionMap and editedText
  ReactionData({this.reactionSet, this.editedText});

  @override
  List<Object?> get props => [reactionSet, editedText];
}
