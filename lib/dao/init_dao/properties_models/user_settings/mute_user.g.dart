// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mute_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MuteUser _$MuteUserFromJson(Map<String, dynamic> json) => MuteUser(
      gid: json['gid'] as int,
      expiredAt: json['expired_at'] as int?,
    );

Map<String, dynamic> _$MuteUserToJson(MuteUser instance) => <String, dynamic>{
      'gid': instance.gid,
      'expired_at': instance.expiredAt,
    };
