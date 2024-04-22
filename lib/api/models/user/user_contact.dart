import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/user/contact_info.dart';
import 'package:vocechat_client/api/models/user/old_user_info.dart';

part 'user_contact.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserContact {
  final int targetUid;
  final OldUserInfo targetInfo;
  final ContactInfo contactInfo;

  UserContact(
      {required this.targetUid,
      required this.targetInfo,
      required this.contactInfo});

  factory UserContact.fromJson(Map<String, dynamic> json) =>
      _$UserContactFromJson(json);

  Map<String, dynamic> toJson() => _$UserContactToJson(this);
}
