import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';

part 'login_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class LoginResponse {
  final String serverId;
  final String token;
  final String refreshToken;
  final int expiredIn;
  final OldUserInfo user;

  LoginResponse(
      this.serverId, this.token, this.refreshToken, this.expiredIn, this.user);

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
