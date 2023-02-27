// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_reg_magic_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendRegMagicTokenResponse _$SendRegMagicTokenResponseFromJson(
        Map<String, dynamic> json) =>
    SendRegMagicTokenResponse(
      newMagicToken: json['new_magic_token'] as String,
      mailIsSent: json['mail_is_sent'] as bool,
    );

Map<String, dynamic> _$SendRegMagicTokenResponseToJson(
        SendRegMagicTokenResponse instance) =>
    <String, dynamic>{
      'new_magic_token': instance.newMagicToken,
      'mail_is_sent': instance.mailIsSent,
    };
