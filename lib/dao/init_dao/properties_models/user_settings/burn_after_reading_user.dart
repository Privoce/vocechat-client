import 'package:json_annotation/json_annotation.dart';

part 'burn_after_reading_user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BurnAfterReadingUser {
  final int uid;
  final int expiresIn;

  BurnAfterReadingUser({
    required this.uid,
    required this.expiresIn,
  });

  factory BurnAfterReadingUser.fromJson(Map<String, dynamic> json) =>
      _$BurnAfterReadingUserFromJson(json);

  Map<String, dynamic> toJson() => _$BurnAfterReadingUserToJson(this);
}
