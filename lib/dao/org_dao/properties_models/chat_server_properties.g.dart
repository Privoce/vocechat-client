// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_server_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatServerProperties _$ChatServerPropertiesFromJson(
        Map<String, dynamic> json) =>
    ChatServerProperties(
      serverName: json['server_name'] as String? ?? "server",
      description: json['description'] as String?,
      config: json['config'] == null
          ? null
          : AdminLoginConfig.fromJson(json['config'] as Map<String, dynamic>),
      commonInfo: json['common_info'] == null
          ? null
          : AdminSystemCommonInfo.fromJson(
              json['common_info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatServerPropertiesToJson(
        ChatServerProperties instance) =>
    <String, dynamic>{
      'server_name': instance.serverName,
      'description': instance.description,
      'config': instance.config,
      'common_info': instance.commonInfo,
    };
