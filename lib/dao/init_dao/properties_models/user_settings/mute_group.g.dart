// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mute_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MuteGroup _$MuteGroupFromJson(Map<String, dynamic> json) => MuteGroup(
      gid: json['gid'] as int,
      expiredAt: json['expired_at'] as int?,
    );

Map<String, dynamic> _$MuteGroupToJson(MuteGroup instance) => <String, dynamic>{
      'gid': instance.gid,
      'expired_at': instance.expiredAt,
    };
