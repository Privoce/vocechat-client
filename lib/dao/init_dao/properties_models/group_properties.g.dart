// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupProperties _$GroupPropertiesFromJson(Map<String, dynamic> json) =>
    GroupProperties(
      json['read_index'] as int,
      json['draft'] as String,
      json['pinned_at'] as int?,
    );

Map<String, dynamic> _$GroupPropertiesToJson(GroupProperties instance) =>
    <String, dynamic>{
      'read_index': instance.readIndex,
      'draft': instance.draft,
      'pinned_at': instance.pinnedAt,
    };
