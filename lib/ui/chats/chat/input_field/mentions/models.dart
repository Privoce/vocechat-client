import 'package:flutter/material.dart';

enum SuggestionPosition { Top, Bottom }

class LengthMap {
  LengthMap({
    required this.start,
    required this.end,
    required this.str,
  });

  String str;
  int start;
  int end;
}

class Mention {
  Mention({
    required this.trigger,
    this.data = const [],
    this.style,
    this.matchAll = false,
    this.suggestionBuilder,
    this.disableMarkup = false,
    this.markupBuilder,
  });

  /// A single character that will be used to trigger the suggestions.
  final String trigger;

  /// List of Map to represent the suggestions shown to the user
  ///
  /// You need to provide two properties `id` & `display` both are [String]
  /// You can also have any custom properties as you like to build custom suggestion
  /// widget.
  final List<Map<String, dynamic>> data;

  /// Style for the mention item in Input.
  final TextStyle? style;

  /// Should every non-suggestion with the trigger character be matched
  final bool matchAll;

  /// Should the markup generation be disabled for this Mention Item.
  final bool disableMarkup;

  /// Build Custom suggestion widget using this builder.
  final Widget Function(Map<String, dynamic>)? suggestionBuilder;

  /// Allows to set custom markup for the mentioned item.
  final String Function(String trigger, String mention, String value)?
      markupBuilder;
}

class Annotation {
  Annotation({
    required this.trigger,
    this.style,
    this.id,
    this.display,
    this.disableMarkup = false,
    this.markupBuilder,
  });

  TextStyle? style;
  String? id;
  String? display;
  String trigger;
  bool disableMarkup;
  final String Function(String trigger, String mention, String value)?
      markupBuilder;
}
