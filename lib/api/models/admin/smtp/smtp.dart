import 'package:json_annotation/json_annotation.dart';

part 'smtp.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AdminSmtp {
  final bool enabled;
  final String host;
  final int port;
  final String from;
  final String username;
  final String password;

  AdminSmtp(
      {this.enabled = true,
      required this.host,
      required this.port,
      required this.from,
      required this.username,
      required this.password});

  factory AdminSmtp.fromJson(Map<String, dynamic> json) =>
      _$AdminSmtpFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSmtpToJson(this);
}
