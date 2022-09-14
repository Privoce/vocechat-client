import 'package:json_annotation/json_annotation.dart';

part 'open_graphic_image.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class OpenGraphicImage {
  final String? alt;
  final int? height;
  late final String? _secureUrl;
  final String? type;
  late final String? _url;
  final int? width;

  OpenGraphicImage(
      {required this.alt,
      required this.height,
      required String? secureUrl,
      required this.type,
      required String? url,
      required this.width}) {
    _secureUrl = secureUrl;
    _url = url;
  }
  String? get secureUrl {
    return _secureUrl;
  }

  String? get url {
    return _url;
  }

  factory OpenGraphicImage.fromJson(Map<String, dynamic> json) =>
      _$OpenGraphicImageFromJson(json);

  Map<String, dynamic> toJson() => _$OpenGraphicImageToJson(this);
}
