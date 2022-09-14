// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_msg_reactions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMsgReactions _$ChatMsgReactionsFromJson(Map<String, dynamic> json) =>
    ChatMsgReactions(
      (json['reactions'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>).map(
                (k, e) => MapEntry(int.parse(k), e as String),
              ))
          .toList(),
    );

Map<String, dynamic> _$ChatMsgReactionsToJson(ChatMsgReactions instance) =>
    <String, dynamic>{
      'reactions': instance.reactions
          .map((e) => e.map((k, e) => MapEntry(k.toString(), e)))
          .toList(),
    };
