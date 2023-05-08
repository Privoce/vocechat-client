// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupProperties _$GroupPropertiesFromJson(Map<String, dynamic> json) =>
    GroupProperties(
      json['burn_after_read_second'] as int,
      json['enable_mute'] as bool,
      json['mute_expires_at'] as int?,
      json['read_index'] as int,
      json['draft'] as String,
      json['pinned_at'] as int?,
    );

Map<String, dynamic> _$GroupPropertiesToJson(GroupProperties instance) =>
    <String, dynamic>{
      'burn_after_read_second': instance.burnAfterReadSecond,
      'enable_mute': instance.enableMute,
      'mute_expires_at': instance.muteExpiresAt,
      'read_index': instance.readIndex,
      'draft': instance.draft,
      'pinned_at': instance.pinnedAt,
    };
