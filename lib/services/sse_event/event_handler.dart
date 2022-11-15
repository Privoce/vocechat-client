/*
import 'dart:convert';

import 'package:vocechat_client/api/models/msg/chat_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_normal.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/models/ui_models/ui_msg.dart';
import 'package:vocechat_client/services/sse_event/sse_event_consts.dart';

class EventHandler {
  static final EventHandler _singleton = EventHandler._instance();
  factory EventHandler() => _singleton;
  EventHandler._instance();

  Future<void> handleSseChats(List<dynamic> messages) async {
    if (messages.isEmpty) return;

    try {
      assert(jsonDecode(messages.first)["type"] == sseChat);
    } catch (e) {
      App.logger.severe(e);
    }

    List<ChatMsgM> chatMsgMs = [];
    for (final msg in messages) {
      try {
        ChatMsg chatMsg = ChatMsg.fromJson(jsonDecode(msg));
        ChatMsgM chatMsgM;

        switch (chatMsg.detail["type"]) {
          case chatMsgNormal:
            chatMsgM = await _handleMsgNormal(chatMsg);
            break;
          case chatMsgReaction:
            chatMsgM = await _handleMsgReaction(chatMsg);
            break;
          case chatMsgReply:
            chatMsgM = await _handleMsgReply(chatMsg);
            break;
          default:
            final errorMsg = "MsgDetail format error. msg: ${chatMsg.toJson()}";
            App.logger.severe(errorMsg);
        }
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  Future<ChatMsgM> _handleMsgNormal(ChatMsg chatMsg) async {
    final detail = MsgNormal.fromJson(chatMsg.detail);
    final isSelf = chatMsg.fromUid == App.app.userDb!.uid;

    String localMid;
    if (isSelf) {
      localMid = detail.properties?['cid'] ?? uuid();
    } else {
      localMid = uuid();
    }

    try {
      ChatMsgM chatMsgM;

      switch (detail.contentType) {
        case typeText:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);
          chatMsgM = await ChatMsgDao().addOrUpdate(chatMsgM);
          final uiMsg = UiMsg(chatMsgM: chatMsgM)

          break;
        case typeMarkdown:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);

          // taskQueue.add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
          //       fireSnippet(value);
          //       fireMsg(value, localMid, detail.content);
          //     }));
          chatMsgM = await ChatMsgDao().addOrUpdate(chatMsgM);

          break;

        case typeFile:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);
          taskQueue.add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
                fireSnippet(chatMsgM);
              }));

          // thumb will only be downloaded if file is an image.
          try {
            if (chatMsgM.isImageMsg) {
              taskQueue.add(() =>
                  FileHandler.singleton.getImageThumb(chatMsgM).then((thumb) {
                    if (thumb != null) {
                      fireMsg(chatMsgM, chatMsgM.localMid, thumb);
                    } else {
                      fireMsg(chatMsgM, localMid, null);
                    }
                  }));
            } else {
              fireMsg(chatMsgM, localMid, null);
            }
          } catch (e) {
            App.logger.severe(e);
          }

          break;

        case typeArchive:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);

          taskQueue
              .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) async {
                    fireSnippet(value);
                  }));

          getArchive(chatMsgM).catchError((e) {
            App.logger.severe(e);
          }).then((value) {
            if (value != null) {
              fireMsg(chatMsgM, localMid, value.archive);
            } else {
              fireMsg(chatMsgM, localMid, null);
            }
          });
          break;
        default:
          break;
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleMsgReaction(ChatMsg chatMsg) async {
    final msgReactionJson = chatMsg.detail;
    final targetMid = msgReactionJson["mid"]!;

    assert(msgReactionJson["type"] == "reaction");

    try {
      final detailJson = msgReactionJson["detail"] as Map<String, dynamic>;

      switch (detailJson["type"]) {
        case "edit":
          final edit = detailJson["content"] as String;

          await ChatMsgDao()
              .editMsgByMid(targetMid, edit, MsgSendStatus.success)
              .then((newMsgM) {
            if (newMsgM != null) {
              fireSnippet(newMsgM);
              fireReaction(ReactionTypes.edit, targetMid, newMsgM);
            }
          });

          break;
        case "like":
          final reaction = detailJson["action"] as String;

          await ChatMsgDao()
              .reactMsgByMid(targetMid, chatMsg.fromUid, reaction,
                  DateTime.now().millisecondsSinceEpoch)
              .then((newMsgM) {
            if (newMsgM != null) {
              fireReaction(ReactionTypes.like, targetMid, newMsgM);
            }
          });

          break;
        case "delete":
          final int? targetMid = chatMsg.detail["mid"];
          if (targetMid == null) return;

          final targetMsgM = await ChatMsgDao().getMsgByMid(targetMid);
          if (targetMsgM == null) return;

          await ChatMsgDao().deleteMsgByMid(targetMsgM).then((mid) async {
            if (mid < 0) {
              return;
            }

            FileHandler.singleton.deleteWithChatMsgM(targetMsgM);
            fireReaction(ReactionTypes.delete, mid);

            // delete without remaining hint words in msg list.
            if (targetMsgM.isGroupMsg) {
              final curMaxMid =
                  await ChatMsgDao().getChannelMaxMid(targetMsgM.gid);
              if (curMaxMid > -1) {
                final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                if (msg != null) {
                  fireSnippet(msg);
                }
              }
            } else {
              final curMaxMid =
                  await ChatMsgDao().getDmMaxMid(targetMsgM.dmUid);
              if (curMaxMid > -1) {
                final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                if (msg != null) {
                  fireSnippet(msg);
                }
              }
            }

            // delete with remaining hint words in msg list.
            // fireSnippet(value, "This message has been deleted.");
            // fireReaction(ReactionTypes.delete, targetMid, value);
          });
          // );
          break;

        default:
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleReply(ChatMsg chatMsg) async {
    final msgReplyJson = chatMsg.detail;

    assert(msgReplyJson["type"] == "reply");

    final isSelf = chatMsg.fromUid == App.app.userDb!.uid;

    String localMid;
    if (isSelf) {
      localMid = chatMsg.detail['properties']?['cid'] ?? uuid();
    } else {
      localMid = uuid();
    }

    try {
      chatMsg.createdAt = chatMsg.createdAt;
      ChatMsgM chatMsgM =
          ChatMsgM.fromReply(chatMsg, localMid, MsgSendStatus.success);
      taskQueue
          .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) async {
                fireSnippet(value);
                fireMsg(value, localMid, msgReplyJson['content']);
              }));
    } catch (e) {
      App.logger.severe(e);
    }
  }
}

*/