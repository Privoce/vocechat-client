// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sys_common_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminSystemCommonInfo _$AdminSystemCommonInfoFromJson(
        Map<String, dynamic> json) =>
    AdminSystemCommonInfo(
      showUserOnlineStatus: json['show_user_online_status'] as bool? ?? true,
      contactVerificationEnable:
          json['contact_verification_enable'] as bool? ?? true,
      chatLayoutMode: json['chat_layout_mode'] as String? ?? "Left",
      maxFileExpiryMode: json['max_file_expiry_mode'] as String? ?? "Off",
    );

Map<String, dynamic> _$AdminSystemCommonInfoToJson(
        AdminSystemCommonInfo instance) =>
    <String, dynamic>{
      'show_user_online_status': instance.showUserOnlineStatus,
      'contact_verification_enable': instance.contactVerificationEnable,
      'chat_layout_mode': instance.chatLayoutMode,
      'max_file_expiry_mode': instance.maxFileExpiryMode,
    };
