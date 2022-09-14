// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MsgReaction _$MsgReactionFromJson(Map<String, dynamic> json) => MsgReaction(
      mid: json['mid'] as int,
      detail: json['detail'] as Map<String, dynamic>,
      type: json['type'] as String? ?? 'reaction',
    );

Map<String, dynamic> _$MsgReactionToJson(MsgReaction instance) =>
    <String, dynamic>{
      'mid': instance.mid,
      'detail': instance.detail,
      'type': instance.type,
    };
