// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oidc_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OidcInfo _$OidcInfoFromJson(Map<String, dynamic> json) => OidcInfo(
      enable: json['enable'] as bool,
      favicon: json['favicon'] as String,
      domain: json['domain'] as String,
    );

Map<String, dynamic> _$OidcInfoToJson(OidcInfo instance) => <String, dynamic>{
      'enable': instance.enable,
      'favicon': instance.favicon,
      'domain': instance.domain,
    };
