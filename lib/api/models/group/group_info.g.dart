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
      json['add_friend'] as bool,
      json['dm_to_member'] as bool,
      json['only_owner_can_send_msg'] as bool,
      json['show_email'] as bool,
      json['ext_settings'] as String?,
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
      'add_friend': instance.addFriend,
      'dm_to_member': instance.dmToMember,
      'only_owner_can_send_msg': instance.onlyOwnerCanSendMsg,
      'show_email': instance.showEmail,
      'ext_settings': instance.extSettings,
    };
