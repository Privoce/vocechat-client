import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';

class AutoDeleteSettingsPage extends StatefulWidget {
  final int? gid;
  final int? uid;
  final int initExpTime;

  AutoDeleteSettingsPage({this.gid, this.uid, required this.initExpTime});
  @override
  State<AutoDeleteSettingsPage> createState() => _AutoDeleteSettingsPageState();
}

class _AutoDeleteSettingsPageState extends State<AutoDeleteSettingsPage> {
  final ValueNotifier<bool> _isUpdating = ValueNotifier(false);

  // close, 30s, 10min, 1hr, 1d, 1week
  final List<int> timeList = [0, 30, 600, 3600, 86400, 604800];
  int _selectedTime = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(AppLocalizations.of(context)!.autoDeleteMessage,
                  style: AppTextStyles.titleLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isUpdating,
              builder: (context, value, child) {
                if (value) {
                  return Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: CupertinoActivityIndicator());
                } else {
                  return SizedBox.shrink();
                }
              },
            )
          ],
        ),
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.barBg,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        actions: [
          CupertinoButton(
              onPressed: _onSubmit,
              child: Text(AppLocalizations.of(context)!.done,
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 17,
                      color: AppColors.primary400)))
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return BannerTileGroup(
      header: AppLocalizations.of(context)!.autoDeleteMessageTitle,
      footer: AppLocalizations.of(context)!.autoDeleteMessageDes,
      bannerTileList: List.generate(timeList.length, (index) {
        final time = timeList[index];
        final title = _translateTime(time);

        return BannerTile(
          title: title,
          keepArrow: false,
          trailing: time == _selectedTime
              ? Icon(AppIcons.select, color: Colors.blue)
              : SizedBox.shrink(),
          onTap: () => _selectTime(time),
        );
      }),
    );
  }

  void _selectTime(int time) async {
    setState(() {
      _selectedTime = time;
    });
  }

  void _onSubmit() async {
    // TODO
  }

  String _translateTime(int seconds) {
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
}
