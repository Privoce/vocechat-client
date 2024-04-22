// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContact _$UserContactFromJson(Map<String, dynamic> json) => UserContact(
      targetUid: json['target_uid'] as int,
      targetInfo:
          OldUserInfo.fromJson(json['target_info'] as Map<String, dynamic>),
      contactInfo:
          ContactInfo.fromJson(json['contact_info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserContactToJson(UserContact instance) =>
    <String, dynamic>{
      'target_uid': instance.targetUid,
      'target_info': instance.targetInfo.toJson(),
      'contact_info': instance.contactInfo.toJson(),
    };
