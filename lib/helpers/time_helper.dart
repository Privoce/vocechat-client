import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension TimeHelper on DateTime {
  String toTime24StringEn(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localtime = toLocal();

    final dateToCheck = DateTime(year, month, day);
    if (dateToCheck == today) {
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } else if (dateToCheck == yesterday) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      final year = localtime.year.toString();
      final month = localtime.month.toString();
      final day = localtime.day.toString();

      return "$month/$day/$year";
    }
  }

  String toChatTime24StrEn(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localtime = toLocal();

    final dateToCheck = DateTime(year, month, day);
    if (dateToCheck == today) {
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "${AppLocalizations.of(context)!.today} $hour:$minute";
    } else if (dateToCheck == yesterday) {
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "${AppLocalizations.of(context)!.yesterday} $hour:$minute";
    } else if (dateToCheck.year == localtime.year) {
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "$month/$day $hour:$minute";
    } else {
      final year = localtime.year.toString();
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "$month/$day/$year $hour:$minute";
    }
  }

  String toChatDateStrEn(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final localtime = toLocal();
    final dateToCheck = DateTime(year, month, day);
    if (dateToCheck == today) {
      return AppLocalizations.of(context)!.today;
    } else if (dateToCheck == yesterday) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (dateToCheck.year == now.year) {
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      return "$month/$day";
    } else {
      final year = localtime.year.toString();
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "$month/$day/$year $hour:$minute";
    }
  }

  String toTime24Str() {
    final localtime = toLocal();

    final hour = localtime.hour.toString();
    final minute = localtime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }
}

extension ChatTimeDisplay on int {
  /*
    microsecond: 1/100,000 second
    millisecond: 1/1,000 second
   */
  String toChatTime24StrEn(BuildContext context) {
    final messageTime = DateTime.fromMillisecondsSinceEpoch(this).toLocal();
    return messageTime.toTime24StringEn(context);
  }
}
