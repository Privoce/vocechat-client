// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agora_channel_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgoraChannelDetail _$AgoraChannelDetailFromJson(Map<String, dynamic> json) =>
    AgoraChannelDetail(
      channelExist: json['channel_exist'] as bool,
      mode: json['mode'] as int,
      total: json['total'] as int,
      users: (json['users'] as List<dynamic>).map((e) => e as int).toList(),
    );

Map<String, dynamic> _$AgoraChannelDetailToJson(AgoraChannelDetail instance) =>
    <String, dynamic>{
      'channel_exist': instance.channelExist,
      'mode': instance.mode,
      'total': instance.total,
      'users': instance.users,
    };
