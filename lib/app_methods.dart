import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Global functions should be put here.

/// Parse mention info in text and markdowns.
/// It changes uid to username when mention format occurs.
Future<String> parseMention(String snippet) async {
  String text;

  Map<int, String> nameMap = {};
  final regex = RegExp(r'\s@[0-9]+\s');

  for (final each in regex.allMatches(snippet)) {
    try {
      final uid =
          int.parse(snippet.substring(each.start, each.end).substring(2));
      final user = await UserInfoDao().getUserByUid(uid);
      final username = user?.userInfo.name ?? uid.toString();
      nameMap.addAll({uid: username});
    } catch (e) {
      App.logger.severe(e);
    }
  }

  text = snippet.splitMapJoin(regex, onMatch: (Match match) {
    final uidStr = match[0]?.substring(2);
    if (uidStr != null && uidStr.isNotEmpty) {
      final uid = int.parse(uidStr);
      return " @" + (nameMap[uid] ?? uidStr) + " ";
    }
    return '';
  }, onNonMatch: (String text) {
    return text;
  });

  return text;
}

/// Get first, or first two, if exists, initials of a name string, used for
/// user avatars.
String getInitials(String input, {int limit = 4}) {
  return input.isNotEmpty
      ? input
          .trim()
          .split(RegExp(
              '[\u0009\u000a\u000b\u000c\u000d\u0020\u0085\u00a0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u200c\u200d\u2028\u2029\u202f\u205f\u2060\u3000\ufeff]+'))
          .map((s) => s.characters.toList()[0])
          .take(limit)
          .join()
          .toUpperCase()
      : '';
}

/// used for path generation when doing file storage
String? getChatId({int? uid, int? gid}) {
  if (uid != null && uid != -1) {
    return "U$uid";
  } else if (gid != null && gid != -1) {
    return "G$gid";
  }
  return null;
}

MsgSendStatus getMsgSendStatus(String status) {
  switch (status) {
    case "success":
      return MsgSendStatus.success;
    case "fail":
      return MsgSendStatus.fail;
    case "readyToSend":
      return MsgSendStatus.readyToSend;
    case "sending":
      return MsgSendStatus.sending;
    default:
      return MsgSendStatus.success;
  }
}

SendType getSendType(ChatMsgM chatMsgM) {
  if (chatMsgM.type == MsgDetailType.normal &&
      (chatMsgM.detailType == MsgContentType.text ||
          chatMsgM.detailType == MsgContentType.markdown) &&
      chatMsgM.edited == 0) {
    return SendType.normal;
  } else if (chatMsgM.detailType == MsgContentType.file) {
    return SendType.file;
  } else if (chatMsgM.type == MsgDetailType.reply) {
    return SendType.reply;
  } else if (chatMsgM.type == MsgDetailType.normal &&
      chatMsgM.detailType == MsgContentType.text &&
      chatMsgM.edited == 1) {
    return SendType.edit;
  }
  return SendType.normal;
}

String translateAutoDeletionTime(int seconds, BuildContext context) {
  if (seconds == 0) {
    return AppLocalizations.of(context)!.off;
  } else if (seconds >= 1 && seconds < 60) {
    if (seconds == 1) {
      return "1 ${AppLocalizations.of(context)!.second}";
    } else {
      return "$seconds ${AppLocalizations.of(context)!.seconds}";
    }
  } else if (seconds >= 60 && seconds < 3600) {
    final minute = seconds ~/ 60;
    if (minute == 1) {
      return "1 ${AppLocalizations.of(context)!.minute}";
    } else {
      return "$minute ${AppLocalizations.of(context)!.minutes}";
    }
  } else if (seconds >= 3600 && seconds < 86400) {
    final hour = seconds ~/ 3600;
    if (hour == 1) {
      return "1 ${AppLocalizations.of(context)!.hour}";
    } else {
      return "$hour ${AppLocalizations.of(context)!.hours}";
    }
  } else if (seconds >= 86400 && seconds < 604800) {
    final day = seconds ~/ 86400;
    if (day == 1) {
      return "1 ${AppLocalizations.of(context)!.day}";
    } else {
      return "$day ${AppLocalizations.of(context)!.days}";
    }
  } else {
    final week = seconds ~/ 604800;
    if (week == 1) {
      return "1 ${AppLocalizations.of(context)!.week}";
    } else {
      return "$week ${AppLocalizations.of(context)!.weeks}";
    }
  }
}

EventBus eventBus = EventBus();

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
