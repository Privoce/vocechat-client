// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProperties _$UserPropertiesFromJson(Map<String, dynamic> json) =>
    UserProperties(
      json['draft'] as String,
      json['pinned_at'] as int?,
    );

Map<String, dynamic> _$UserPropertiesToJson(UserProperties instance) =>
    <String, dynamic>{
      'draft': instance.draft,
      'pinned_at': instance.pinnedAt,
    };
