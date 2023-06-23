// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
      burnAfterReadingGroups: (json['burn_after_reading_groups']
              as List<dynamic>)
          .map((e) => BurnAfterReadingGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      burnAfterReadingUsers: (json['burn_after_reading_users'] as List<dynamic>)
          .map((e) => BurnAfterReadingUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      muteGroups: (json['mute_groups'] as List<dynamic>)
          .map((e) => MuteGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      muteUsers: (json['mute_users'] as List<dynamic>)
          .map((e) => MuteUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      pinnedChats: (json['pinned_chats'] as List<dynamic>)
          .map((e) => PinnedChat.fromJson(e as Map<String, dynamic>))
          .toList(),
      readIndexGroups: (json['read_index_groups'] as List<dynamic>)
          .map((e) => ReadIndexGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      readIndexUsers: (json['read_index_users'] as List<dynamic>)
          .map((e) => ReadIndexUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'burn_after_reading_groups':
          instance.burnAfterReadingGroups.map((e) => e.toJson()).toList(),
      'burn_after_reading_users':
          instance.burnAfterReadingUsers.map((e) => e.toJson()).toList(),
      'mute_groups': instance.muteGroups.map((e) => e.toJson()).toList(),
      'mute_users': instance.muteUsers.map((e) => e.toJson()).toList(),
      'pinned_chats': instance.pinnedChats.map((e) => e.toJson()).toList(),
      'read_index_groups':
          instance.readIndexGroups.map((e) => e.toJson()).toList(),
      'read_index_users':
          instance.readIndexUsers.map((e) => e.toJson()).toList(),
    };
