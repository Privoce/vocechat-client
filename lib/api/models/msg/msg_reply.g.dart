// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MsgReply _$MsgReplyFromJson(Map<String, dynamic> json) => MsgReply(
      mid: json['mid'] as int,
      contentType: json['content_type'] as String,
      content: json['content'] as String,
      properties: json['properties'] as Map<String, dynamic>?,
      type: json['type'] as String? ?? 'reply',
    );

Map<String, dynamic> _$MsgReplyToJson(MsgReply instance) => <String, dynamic>{
      'mid': instance.mid,
      'properties': instance.properties,
      'content_type': instance.contentType,
      'content': instance.content,
      'type': instance.type,
    };
