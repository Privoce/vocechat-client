// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agora_channel_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgoraChannelData _$AgoraChannelDataFromJson(Map<String, dynamic> json) =>
    AgoraChannelData(
      channels: (json['channels'] as List<dynamic>)
          .map((e) => AgoraChannel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSize: json['total_size'] as int,
    );

Map<String, dynamic> _$AgoraChannelDataToJson(AgoraChannelData instance) =>
    <String, dynamic>{
      'channels': instance.channels.map((e) => e.toJson()).toList(),
      'total_size': instance.totalSize,
    };
