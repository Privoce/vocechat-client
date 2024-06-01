// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    LoginRequestDto(
      credential: json['credential'] == null
          ? null
          : LoginCredentialDto.fromJson(
              json['credential'] as Map<String, dynamic>),
      device: json['device'] as String?,
      deviceToken: json['device_token'] as String?,
    )..type = json['type'] as String?;

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'credential': instance.credential?.toJson(),
      'device': instance.device,
      'device_token': instance.deviceToken,
    };
