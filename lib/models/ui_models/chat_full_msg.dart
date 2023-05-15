import 'dart:core';

import 'package:equatable/equatable.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';

import '../../dao/init_dao/reaction.dart';

// ignore: must_be_immutable
class ChatFullMsg extends Equatable {
  /// The full message of a chat message.
  ///
  /// This class is used to store the full message of a chat message, including
  /// the chat message itself, the reaction data, which includes .
  ChatFullMsg(this.chatMsgM, {this.reactionData});

  ChatMsgM chatMsgM;

  ReactionData? reactionData;

  @override
  List<Object?> get props => [chatMsgM, reactionData];
}
