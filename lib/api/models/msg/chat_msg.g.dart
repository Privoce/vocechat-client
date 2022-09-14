// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_msg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMsg _$ChatMsgFromJson(Map<String, dynamic> json) => ChatMsg(
      mid: json['mid'] as int,
      fromUid: json['from_uid'] as int,
      createdAt: json['created_at'] as int,
      target: json['target'] as Map<String, dynamic>,
      detail: json['detail'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ChatMsgToJson(ChatMsg instance) => <String, dynamic>{
      'mid': instance.mid,
      'from_uid': instance.fromUid,
      'created_at': instance.createdAt,
      'target': instance.target,
      'detail': instance.detail,
    };
