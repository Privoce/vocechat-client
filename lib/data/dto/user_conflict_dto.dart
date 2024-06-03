import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/data/enum/create_user_conflict_reason.dart';

part 'user_conflict_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserConflictDto {
  String? reason;

  UserConflictDto({this.reason});

  factory UserConflictDto.fromJson(Map<String, dynamic> json) =>
      _$UserConflictDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserConflictDtoToJson(this);

  CreateUserConflictReason? get reasonString {
    switch (reason) {
      case 'email_conflict':
        return CreateUserConflictReason.email;
      case 'name_conflict':
        return CreateUserConflictReason.name;
    }
    return null;
  }
}
