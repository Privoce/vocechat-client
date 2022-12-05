// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeLog _$ChangeLogFromJson(Map<String, dynamic> json) => ChangeLog(
      latest: ChangeLogLatest.fromJson(json['latest'] as Map<String, dynamic>),
      logs: (json['logs'] as List<dynamic>)
          .map((e) => ChangeLogHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChangeLogToJson(ChangeLog instance) => <String, dynamic>{
      'latest': instance.latest.toJson(),
      'logs': instance.logs.map((e) => e.toJson()).toList(),
    };
