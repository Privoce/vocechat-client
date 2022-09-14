// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupUpdateRequest _$GroupUpdateRequestFromJson(Map<String, dynamic> json) =>
    GroupUpdateRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      owner: json['owner'] as int?,
    );

Map<String, dynamic> _$GroupUpdateRequestToJson(GroupUpdateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'owner': instance.owner,
    };
