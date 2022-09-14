// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupCreateRequest _$GroupCreateRequestFromJson(Map<String, dynamic> json) =>
    GroupCreateRequest(
      name: json['name'] as String,
      description: json['description'] as String,
      isPublic: json['is_public'] as bool,
      members:
          (json['members'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );

Map<String, dynamic> _$GroupCreateRequestToJson(GroupCreateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'members': instance.members,
      'is_public': instance.isPublic,
    };
