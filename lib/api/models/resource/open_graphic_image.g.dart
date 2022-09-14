// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_graphic_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenGraphicImage _$OpenGraphicImageFromJson(Map<String, dynamic> json) =>
    OpenGraphicImage(
      alt: json['alt'] as String?,
      height: json['height'] as int?,
      secureUrl: json['secure_url'] as String?,
      type: json['type'] as String?,
      url: json['url'] as String?,
      width: json['width'] as int?,
    );

Map<String, dynamic> _$OpenGraphicImageToJson(OpenGraphicImage instance) =>
    <String, dynamic>{
      'alt': instance.alt,
      'height': instance.height,
      'type': instance.type,
      'width': instance.width,
      'secure_url': instance.secureUrl,
      'url': instance.url,
    };
