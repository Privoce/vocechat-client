// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_renew_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenRenewResponse _$TokenRenewResponseFromJson(Map<String, dynamic> json) =>
    TokenRenewResponse(
      json['token'] as String,
      json['refresh_token'] as String,
      json['expired_in'] as int,
    );

Map<String, dynamic> _$TokenRenewResponseToJson(TokenRenewResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'expired_in': instance.expiredIn,
    };
