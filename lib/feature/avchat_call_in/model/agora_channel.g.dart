// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agora_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgoraChannel _$AgoraChannelFromJson(Map<String, dynamic> json) => AgoraChannel(
      userCount: json['user_count'] as int,
      channelname: json['channelname'] as String,
    );

Map<String, dynamic> _$AgoraChannelToJson(AgoraChannel instance) =>
    <String, dynamic>{
      'user_count': instance.userCount,
      'channelname': instance.channelname,
    };
