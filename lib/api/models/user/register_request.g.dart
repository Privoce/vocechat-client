// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      magicToken: json['magic_token'] as String?,
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String? ?? "New User",
      gender: json['gender'] as int? ?? 0,
      language: json['language'] as String? ?? "en-US",
      device: json['device'] as String? ?? "iOS",
      deviceToken: json['device_token'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'magic_token': instance.magicToken,
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'gender': instance.gender,
      'language': instance.language,
      'device': instance.device,
      'device_token': instance.deviceToken,
    };
