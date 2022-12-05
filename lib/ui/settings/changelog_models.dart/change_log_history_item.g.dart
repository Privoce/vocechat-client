// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_log_history_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeLogHistoryItem _$ChangeLogHistoryItemFromJson(
        Map<String, dynamic> json) =>
    ChangeLogHistoryItem(
      time: json['time'] as int,
      version: json['version'] as String,
      buildNum: json['build_num'] as int,
      updates: json['updates'] as List<dynamic>,
    );

Map<String, dynamic> _$ChangeLogHistoryItemToJson(
        ChangeLogHistoryItem instance) =>
    <String, dynamic>{
      'time': instance.time,
      'version': instance.version,
      'build_num': instance.buildNum,
      'updates': instance.updates,
    };
