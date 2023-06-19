// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agora_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgoraTokenResponse _$AgoraTokenResponseFromJson(Map<String, dynamic> json) =>
    AgoraTokenResponse(
      agoraToken: json['agora_token'] as String,
      appId: json['app_id'] as String,
      uid: json['uid'] as int,
      channelName: json['channel_name'] as String,
      expiredIn: json['expired_in'] as int,
    );

Map<String, dynamic> _$AgoraTokenResponseToJson(AgoraTokenResponse instance) =>
    <String, dynamic>{
      'agora_token': instance.agoraToken,
      'app_id': instance.appId,
      'uid': instance.uid,
      'channel_name': instance.channelName,
      'expired_in': instance.expiredIn,
    };
