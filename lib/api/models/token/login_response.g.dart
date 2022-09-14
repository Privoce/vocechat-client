// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      json['server_id'] as String,
      json['token'] as String,
      json['refresh_token'] as String,
      json['expired_in'] as int,
      UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'server_id': instance.serverId,
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'expired_in': instance.expiredIn,
      'user': instance.user.toJson(),
    };
