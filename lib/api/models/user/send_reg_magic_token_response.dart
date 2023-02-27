import 'package:json_annotation/json_annotation.dart';

part 'send_reg_magic_token_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SendRegMagicTokenResponse {
  final String newMagicToken;
  final bool mailIsSent;

  SendRegMagicTokenResponse(
      {required this.newMagicToken, required this.mailIsSent});

  factory SendRegMagicTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$SendRegMagicTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendRegMagicTokenResponseToJson(this);
}
