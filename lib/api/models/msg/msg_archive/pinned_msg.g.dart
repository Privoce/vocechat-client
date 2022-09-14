// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_msg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinnedMsg _$PinnedMsgFromJson(Map<String, dynamic> json) => PinnedMsg(
      mid: json['mid'] as int,
      createdAt: json['created_at'] as int,
      createdBy: json['created_by'] as int,
      properties: json['properties'] as Map<String, dynamic>?,
      content: json['content'] as String,
      contentType: json['content_type'] as String,
    );

Map<String, dynamic> _$PinnedMsgToJson(PinnedMsg instance) => <String, dynamic>{
      'mid': instance.mid,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt,
      'properties': instance.properties,
      'content_type': instance.contentType,
      'content': instance.content,
    };
