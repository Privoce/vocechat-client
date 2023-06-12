class InputFieldTag {
  final String symbol;

  /// The start index of the symbol in the input field.
  ///
  /// Includes the symbol. For example: '@Vincent', it notes the index of '@'.
  final int startIndex;
  final String tag;

  /// The start index of the content in the input field.
  ///
  /// Excludes the symbol. For example: '@Vincent', it notes the index of 'Vincent'.
  int get tagStartIndex => startIndex + symbol.length;

  int get endIndex => tagStartIndex + tag.length;

  InputFieldTag({
    required this.symbol,
    required this.startIndex,
    required this.tag,
  });
}
