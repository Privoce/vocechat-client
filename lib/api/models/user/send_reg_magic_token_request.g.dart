// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_reg_magic_token_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendRegMagicTokenRequest _$SendRegMagicTokenRequestFromJson(
        Map<String, dynamic> json) =>
    SendRegMagicTokenRequest(
      magicToken: json['magic_token'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$SendRegMagicTokenRequestToJson(
        SendRegMagicTokenRequest instance) =>
    <String, dynamic>{
      'magic_token': instance.magicToken,
      'email': instance.email,
      'password': instance.password,
    };
