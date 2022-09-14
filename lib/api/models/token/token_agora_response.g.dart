// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_agora_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenAgoraResponse _$TokenAgoraResponseFromJson(Map<String, dynamic> json) =>
    TokenAgoraResponse(
      json['agora_token'] as String,
      json['app_id'] as String,
      json['uid'] as int,
      json['channel_name'] as String,
      json['expired_in'] as int,
    );

Map<String, dynamic> _$TokenAgoraResponseToJson(TokenAgoraResponse instance) =>
    <String, dynamic>{
      'agora_token': instance.agoraToken,
      'app_id': instance.appId,
      'uid': instance.uid,
      'channel_name': instance.channelName,
      'expired_in': instance.expiredIn,
    };
