// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_normal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MsgNormal _$MsgNormalFromJson(Map<String, dynamic> json) => MsgNormal(
      properties: json['properties'] as Map<String, dynamic>?,
      contentType: json['content_type'] as String,
      content: json['content'] as String,
      expiresIn: json['expires_in'] as int?,
      type: json['type'] as String? ?? 'normal',
    );

Map<String, dynamic> _$MsgNormalToJson(MsgNormal instance) => <String, dynamic>{
      'properties': instance.properties,
      'content_type': instance.contentType,
      'content': instance.content,
      'expires_in': instance.expiresIn,
      'type': instance.type,
    };
