// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupInfo _$GroupInfoFromJson(Map<String, dynamic> json) => GroupInfo(
      json['gid'] as int,
      json['owner'] as int?,
      json['name'] as String,
      json['description'] as String?,
      (json['members'] as List<dynamic>?)?.map((e) => e as int).toList(),
      json['is_public'] as bool,
      json['avatar_updated_at'] as int,
      (json['pinned_messages'] as List<dynamic>)
          .map((e) => PinnedMsg.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GroupInfoToJson(GroupInfo instance) => <String, dynamic>{
      'gid': instance.gid,
      'owner': instance.owner,
      'name': instance.name,
      'description': instance.description,
      'members': instance.members,
      'avatar_updated_at': instance.avatarUpdatedAt,
      'pinned_messages':
          instance.pinnedMessages.map((e) => e.toJson()).toList(),
      'is_public': instance.isPublic,
    };
