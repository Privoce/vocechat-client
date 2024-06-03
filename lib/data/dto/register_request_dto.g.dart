// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequestDto _$RegisterRequestDtoFromJson(Map<String, dynamic> json) =>
    RegisterRequestDto(
      magicToken: json['magic_token'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      birthday: json['birthday'] as String?,
      name: json['name'] as String?,
      gender: json['gender'] as int?,
      language: json['language'] as String?,
      device: json['device'] as String?,
      deviceToken: json['device_token'] as String?,
    );

Map<String, dynamic> _$RegisterRequestDtoToJson(RegisterRequestDto instance) =>
    <String, dynamic>{
      'magic_token': instance.magicToken,
      'email': instance.email,
      'password': instance.password,
      'birthday': instance.birthday,
      'name': instance.name,
      'gender': instance.gender,
      'language': instance.language,
      'device': instance.device,
      'device_token': instance.deviceToken,
    };
