// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'burn_after_reading_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BurnAfterReadingUser _$BurnAfterReadingUserFromJson(
        Map<String, dynamic> json) =>
    BurnAfterReadingUser(
      uid: json['uid'] as int,
      expiresIn: json['expires_in'] as int,
    );

Map<String, dynamic> _$BurnAfterReadingUserToJson(
        BurnAfterReadingUser instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'expires_in': instance.expiresIn,
    };
