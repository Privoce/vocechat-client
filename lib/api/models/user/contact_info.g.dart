// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactInfo _$ContactInfoFromJson(Map<String, dynamic> json) => ContactInfo(
      status: json['status'] as String,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
    );

Map<String, dynamic> _$ContactInfoToJson(ContactInfo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
