extension StringExt on String {
  // url RegEx strings in app_consts.dart
  // All other RegExes should be put here.

  static const emailRegEx =
      r"^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
  static const serverUrlRegEx =
      r"^https?:\/\/\w+(\.\w+)*(:[0-9]+)?\/?(\/[.\w]*)*$";
  static const hasNumberRegEx = r"[0-9]+";
  static const hasLetter = r"[a-zA-Z]+";
  static const hasMin6Chats = r".{6,}";
  static const ytbUrl =
      r"^(?:https?:\/\/)?(?:m\.|www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$";

  bool get isEmail {
    return RegExp(emailRegEx).hasMatch(this);
  }

  bool get isValidPswd {
    // return RegExp(hasNumberRegEx).hasMatch(this) &&
    //     RegExp(hasLetter).hasMatch(this) &&
    //     RegExp(hasMin6Chats).hasMatch(this);
    return RegExp(hasMin6Chats).hasMatch(this);
  }

  bool get isUrl {
    return RegExp(serverUrlRegEx).hasMatch(this);
  }

  bool get isYoutube {
    return RegExp(ytbUrl).hasMatch(this);
  }
}
