import 'package:json_annotation/json_annotation.dart';

part 'oidc_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class OidcInfo {
  bool enable;
  String favicon;
  String domain;

  OidcInfo({required this.enable, required this.favicon, required this.domain});

  factory OidcInfo.fromJson(Map<String, dynamic> json) =>
      _$OidcInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OidcInfoToJson(this);
}
