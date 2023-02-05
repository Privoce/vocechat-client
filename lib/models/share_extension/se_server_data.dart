import 'package:json_annotation/json_annotation.dart';

part 'se_server_data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SEServerData {
  final String token;
  final Map<String, dynamic> userList;
  final Map<String, dynamic> channelList;

  SEServerData(
      {required this.token, required this.userList, required this.channelList});

  factory SEServerData.fromJson(Map<String, dynamic> json) =>
      _$SEServerDataFromJson(json);

  Map<String, dynamic> toJson() => _$SEServerDataToJson(this);
}
