import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RegisterRequest {
  String? magicToken;
  String email;
  String password;
  String? name;
  int gender;
  String language;
  String device;
  String? deviceToken;

  RegisterRequest(
      {this.magicToken,
      required this.email,
      required this.password,
      this.name = "New User",
      this.gender = 0,
      this.language = "en-US",
      this.device = "iOS",
      this.deviceToken});

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
