// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agora_token_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgoraTokenInfo _$AgoraTokenInfoFromJson(Map<String, dynamic> json) =>
    AgoraTokenInfo(
      agoraToken: json['agora_token'] as String,
      appId: json['app_id'] as String,
      uid: json['uid'] as int,
      channelName: json['channel_name'] as String,
      expiredIn: json['expired_in'] as int,
    );

Map<String, dynamic> _$AgoraTokenInfoToJson(AgoraTokenInfo instance) =>
    <String, dynamic>{
      'agora_token': instance.agoraToken,
      'app_id': instance.appId,
      'uid': instance.uid,
      'channel_name': instance.channelName,
      'expired_in': instance.expiredIn,
    };
