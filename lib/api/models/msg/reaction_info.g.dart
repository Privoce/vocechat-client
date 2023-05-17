// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReactionInfo _$ReactionInfoFromJson(Map<String, dynamic> json) => ReactionInfo(
      fromUid: json['from_uid'] as int,
      emoji: json['emoji'] as String,
      createdAt: json['created_at'] as int,
    );

Map<String, dynamic> _$ReactionInfoToJson(ReactionInfo instance) =>
    <String, dynamic>{
      'from_uid': instance.fromUid,
      'emoji': instance.emoji,
      'created_at': instance.createdAt,
    };
