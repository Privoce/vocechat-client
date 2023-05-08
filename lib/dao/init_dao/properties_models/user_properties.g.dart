// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProperties _$UserPropertiesFromJson(Map<String, dynamic> json) =>
    UserProperties(
      json['burn_after_read_second'] as int,
      json['enable_mute'] as bool,
      json['mute_expires_at'] as int?,
      json['read_index'] as int,
      json['draft'] as String,
      json['pinned_at'] as int?,
    );

Map<String, dynamic> _$UserPropertiesToJson(UserProperties instance) =>
    <String, dynamic>{
      'burn_after_read_second': instance.burnAfterReadSecond,
      'enable_mute': instance.enableMute,
      'mute_expires_at': instance.muteExpiresAt,
      'read_index': instance.readIndex,
      'draft': instance.draft,
      'pinned_at': instance.pinnedAt,
    };
