// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_prepare_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilePrepareRequest _$FilePrepareRequestFromJson(Map<String, dynamic> json) =>
    FilePrepareRequest(
      contentType: json['content_type'] as String,
      filename: json['filename'] as String,
    );

Map<String, dynamic> _$FilePrepareRequestToJson(FilePrepareRequest instance) =>
    <String, dynamic>{
      'content_type': instance.contentType,
      'filename': instance.filename,
    };
