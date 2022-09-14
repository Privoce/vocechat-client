// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Archive _$ArchiveFromJson(Map<String, dynamic> json) => Archive(
      users: (json['users'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      numAttachments: json['num_attachments'] as int,
    );

Map<String, dynamic> _$ArchiveToJson(Archive instance) => <String, dynamic>{
      'num_attachments': instance.numAttachments,
      'users': instance.users.map((e) => e.toJson()).toList(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
    };
