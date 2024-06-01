// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      serverId: json['server_id'] as String?,
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiredIn: json['expired_in'] as int?,
      user: json['user'] == null
          ? null
          : UserInfoDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseDtoToJson(LoginResponseDto instance) =>
    <String, dynamic>{
      'server_id': instance.serverId,
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'expired_in': instance.expiredIn,
      'user': instance.user?.toJson(),
    };
