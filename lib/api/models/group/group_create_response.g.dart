// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_create_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupCreateResponse _$GroupCreateResponseFromJson(Map<String, dynamic> json) =>
    GroupCreateResponse(
      gid: json['gid'] as int,
      createdAt: json['created_at'] as int,
    );

Map<String, dynamic> _$GroupCreateResponseToJson(
        GroupCreateResponse instance) =>
    <String, dynamic>{
      'gid': instance.gid,
      'created_at': instance.createdAt,
    };
