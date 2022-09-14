// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminFcm _$AdminFcmFromJson(Map<String, dynamic> json) => AdminFcm(
      enabled: json['enabled'] as bool? ?? true,
      tokenUrl:
          json['token_url'] as String? ?? "https://oauth2.googleapis.com/token",
      projectId: json['project_id'] as String?,
      privateKey: json['private_key'] as String?,
      clientEmail: json['client_email'] as String?,
    );

Map<String, dynamic> _$AdminFcmToJson(AdminFcm instance) => <String, dynamic>{
      'enabled': instance.enabled,
      'token_url': instance.tokenUrl,
      'project_id': instance.projectId,
      'private_key': instance.privateKey,
      'client_email': instance.clientEmail,
    };
