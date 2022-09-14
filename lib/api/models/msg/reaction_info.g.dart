// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReactionInfo _$ReactionInfoFromJson(Map<String, dynamic> json) => ReactionInfo(
      json['from_uid'] as int,
      json['reaction'] as String,
      json['created_at'] as int,
    );

Map<String, dynamic> _$ReactionInfoToJson(ReactionInfo instance) =>
    <String, dynamic>{
      'from_uid': instance.fromUid,
      'reaction': instance.reaction,
      'created_at': instance.createdAt,
    };
