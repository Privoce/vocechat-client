// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'se_server_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SEServerData _$SEServerDataFromJson(Map<String, dynamic> json) => SEServerData(
      token: json['token'] as String,
      userList: json['user_list'] as Map<String, dynamic>,
      channelList: json['channel_list'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$SEServerDataToJson(SEServerData instance) =>
    <String, dynamic>{
      'token': instance.token,
      'user_list': instance.userList,
      'channel_list': instance.channelList,
    };
