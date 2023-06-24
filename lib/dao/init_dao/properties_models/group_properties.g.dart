// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupProperties _$GroupPropertiesFromJson(Map<String, dynamic> json) =>
    GroupProperties(
      json['draft'] as String,
      json['pinned_at'] as int?,
    );

Map<String, dynamic> _$GroupPropertiesToJson(GroupProperties instance) =>
    <String, dynamic>{
      'draft': instance.draft,
      'pinned_at': instance.pinnedAt,
    };
