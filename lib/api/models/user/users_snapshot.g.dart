// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsersSnapshot _$UsersSnapshotFromJson(Map<String, dynamic> json) =>
    UsersSnapshot(
      version: json['version'] as int,
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => UserInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UsersSnapshotToJson(UsersSnapshot instance) =>
    <String, dynamic>{
      'users': instance.users?.map((e) => e.toJson()).toList(),
      'version': instance.version,
    };
