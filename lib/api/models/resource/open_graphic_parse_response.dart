import 'package:json_annotation/json_annotation.dart';

import 'open_graphic_image.dart';

part 'open_graphic_parse_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class OpenGraphicParseResponse {
  final String type;
  late final String? _title;
  late final String? _url;
  late final List<Map<String, dynamic>> _images;
  final List<Map<String, dynamic>> audios;
  final List<Map<String, dynamic>> videos;
  final String? faviconUrl;
  late final String? _description;
  final String? locale;
  final List<String>? localeAlternate;
  late final String? _siteName;
  OpenGraphicParseResponse(
      {required this.type,
      required String title,
      required String url,
      required List<Map<String, dynamic>> images,
      required this.audios,
      required this.videos,
      required this.faviconUrl,
      required String? description,
      this.locale,
      this.localeAlternate,
      required String? siteName}) {
    _title = title;
    _url = url;
    _images = images;
    _description = description;
    _siteName = siteName;
  }

  List<OpenGraphicImage> get images {
    return _images.map((e) => OpenGraphicImage.fromJson(e)).toList();
  }

  String get url {
    return _url ?? '';
  }

  String get title {
    return _title ?? '';
  }

  String get description {
    return _description ?? '';
  }

  String get siteName {
    return _siteName ?? '';
  }

  factory OpenGraphicParseResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenGraphicParseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenGraphicParseResponseToJson(this);
}
