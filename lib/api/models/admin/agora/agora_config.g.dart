// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agora_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgoraConfig _$AgoraConfigFromJson(Map<String, dynamic> json) => AgoraConfig(
      enabled: json['enabled'] as bool,
      url: json['url'] as String? ?? "https://api.agora.io",
      projectId: json['project_id'] as String,
      appId: json['app_id'] as String,
      appCertificate: json['app_certificate'] as String,
      customerId: json['customer_id'] as String,
      customerSecret: json['customer_secret'] as String,
    );

Map<String, dynamic> _$AgoraConfigToJson(AgoraConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'url': instance.url,
      'project_id': instance.projectId,
      'app_id': instance.appId,
      'app_certificate': instance.appCertificate,
      'customer_id': instance.customerId,
      'customer_secret': instance.customerSecret,
    };
