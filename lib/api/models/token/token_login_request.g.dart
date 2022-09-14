// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenLoginRequest _$TokenLoginRequestFromJson(Map<String, dynamic> json) =>
    TokenLoginRequest(
      credential:
          Credential.fromJson(json['credential'] as Map<String, dynamic>),
      device: json['device'] as String? ?? "iPhone",
      deviceToken: json['device_token'] as String? ?? "",
    );

Map<String, dynamic> _$TokenLoginRequestToJson(TokenLoginRequest instance) =>
    <String, dynamic>{
      'device': instance.device,
      'device_token': instance.deviceToken,
      'credential': instance.credential.toJson(),
    };
