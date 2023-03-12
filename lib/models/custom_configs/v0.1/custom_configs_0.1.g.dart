// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_configs_0.1.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomConfigs0001 _$CustomConfigs0001FromJson(Map<String, dynamic> json) =>
    CustomConfigs0001(
      version: json['version'] as String? ?? "0.1",
      configs: Configs0001.fromJson(json['configs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CustomConfigs0001ToJson(CustomConfigs0001 instance) =>
    <String, dynamic>{
      'version': instance.version,
      'configs': instance.configs.toJson(),
    };
