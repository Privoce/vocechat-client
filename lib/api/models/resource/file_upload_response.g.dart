// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_upload_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileUploadResponse _$FileUploadResponseFromJson(Map<String, dynamic> json) =>
    FileUploadResponse(
      path: json['path'] as String,
      size: json['size'] as int,
      hash: json['hash'] as String,
      imageProperties: json['image_properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FileUploadResponseToJson(FileUploadResponse instance) =>
    <String, dynamic>{
      'path': instance.path,
      'size': instance.size,
      'hash': instance.hash,
      'image_properties': instance.imageProperties,
    };
