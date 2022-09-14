// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smtp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminSmtp _$AdminSmtpFromJson(Map<String, dynamic> json) => AdminSmtp(
      enabled: json['enabled'] as bool? ?? true,
      host: json['host'] as String,
      port: json['port'] as int,
      from: json['from'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$AdminSmtpToJson(AdminSmtp instance) => <String, dynamic>{
      'enabled': instance.enabled,
      'host': instance.host,
      'port': instance.port,
      'from': instance.from,
      'username': instance.username,
      'password': instance.password,
    };
