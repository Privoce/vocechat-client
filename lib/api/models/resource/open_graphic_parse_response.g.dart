// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_graphic_parse_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenGraphicParseResponse _$OpenGraphicParseResponseFromJson(
        Map<String, dynamic> json) =>
    OpenGraphicParseResponse(
      type: json['type'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      images: (json['images'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      audios: (json['audios'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      videos: (json['videos'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      faviconUrl: json['favicon_url'] as String?,
      description: json['description'] as String?,
      locale: json['locale'] as String?,
      localeAlternate: (json['locale_alternate'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      siteName: json['site_name'] as String?,
    );

Map<String, dynamic> _$OpenGraphicParseResponseToJson(
        OpenGraphicParseResponse instance) =>
    <String, dynamic>{
      'type': instance.type,
      'audios': instance.audios,
      'videos': instance.videos,
      'favicon_url': instance.faviconUrl,
      'locale': instance.locale,
      'locale_alternate': instance.localeAlternate,
      'images': instance.images.map((e) => e.toJson()).toList(),
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
      'site_name': instance.siteName,
    };
