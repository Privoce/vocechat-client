// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinnedChat _$PinnedChatFromJson(Map<String, dynamic> json) => PinnedChat(
      target: Map<String, int>.from(json['target'] as Map),
      updatedAt: json['updated_at'] as int,
    );

Map<String, dynamic> _$PinnedChatToJson(PinnedChat instance) =>
    <String, dynamic>{
      'target': instance.target,
      'updated_at': instance.updatedAt,
    };
