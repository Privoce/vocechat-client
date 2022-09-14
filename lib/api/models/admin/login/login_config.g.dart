// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoginConfig _$AdminLoginConfigFromJson(Map<String, dynamic> json) =>
    AdminLoginConfig(
      whoCanSignUp: json['who_can_sign_up'] as String,
      password: json['password'] as bool,
      magicLink: json['magic_link'] as bool,
      google: json['google'] as bool,
      github: json['github'] as bool,
      oidc: (json['oidc'] as List<dynamic>)
          .map((e) => OidcInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      metamask: json['metamask'] as bool,
      thirdParty: json['third_party'] as bool,
    );

Map<String, dynamic> _$AdminLoginConfigToJson(AdminLoginConfig instance) =>
    <String, dynamic>{
      'who_can_sign_up': instance.whoCanSignUp,
      'password': instance.password,
      'magic_link': instance.magicLink,
      'google': instance.google,
      'github': instance.github,
      'oidc': instance.oidc.map((e) => e.toJson()).toList(),
      'metamask': instance.metamask,
      'third_party': instance.thirdParty,
    };
