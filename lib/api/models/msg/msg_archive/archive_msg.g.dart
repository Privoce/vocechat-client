// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_msg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArchiveMsg _$ArchiveMsgFromJson(Map<String, dynamic> json) => ArchiveMsg(
      fromUser: json['from_user'] as int,
      createdAt: json['created_at'] as int,
      mid: json['mid'] as int,
      source: json['source'] as Map<String, dynamic>,
      properties: json['properties'] as Map<String, dynamic>?,
      contentType: json['content_type'] as String,
      content: json['content'] as String?,
      fileId: json['file_id'] as int?,
      thumbnailId: json['thumbnail_id'] as int?,
    );

Map<String, dynamic> _$ArchiveMsgToJson(ArchiveMsg instance) =>
    <String, dynamic>{
      'from_user': instance.fromUser,
      'created_at': instance.createdAt,
      'mid': instance.mid,
      'source': instance.source,
      'properties': instance.properties,
      'content_type': instance.contentType,
      'content': instance.content,
      'file_id': instance.fileId,
      'thumbnail_id': instance.thumbnailId,
    };
