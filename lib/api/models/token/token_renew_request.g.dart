// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_renew_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenRenewRequest _$TokenRenewRequestFromJson(Map<String, dynamic> json) =>
    TokenRenewRequest(
      json['token'] as String,
      json['refresh_token'] as String,
    );

Map<String, dynamic> _$TokenRenewRequestToJson(TokenRenewRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refresh_token': instance.refreshToken,
    };
