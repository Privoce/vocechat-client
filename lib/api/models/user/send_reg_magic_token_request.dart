import 'package:json_annotation/json_annotation.dart';

part 'send_reg_magic_token_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SendRegMagicTokenRequest {
  final String magicToken;
  final String email;
  final String password;

  SendRegMagicTokenRequest(
      {required this.magicToken, required this.email, required this.password});

  factory SendRegMagicTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$SendRegMagicTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendRegMagicTokenRequestToJson(this);
}
