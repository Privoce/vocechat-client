import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';

class AutoDeleteSettingsPage extends StatefulWidget {
  final int initExpTime;
  final Future<bool> Function(int expiresIn) onSubmit;

  AutoDeleteSettingsPage({required this.initExpTime, required this.onSubmit});
  @override
  State<AutoDeleteSettingsPage> createState() => _AutoDeleteSettingsPageState();
}

class _AutoDeleteSettingsPageState extends State<AutoDeleteSettingsPage> {
  final ValueNotifier<bool> _isUpdating = ValueNotifier(false);
  final ValueNotifier<bool> _enableDoneBtn = ValueNotifier(false);

  // close, 5min, 10min, 1hr, 1d, 1week
  final List<int> timeList = [0, 300, 600, 3600, 86400, 604800];
  late int _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initExpTime;
  }

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
          ValueListenableBuilder<bool>(
              valueListenable: _enableDoneBtn,
              builder: (context, enable, _) {
                return CupertinoButton(
                    onPressed: enable ? _onSubmit : null,
                    child: Text(AppLocalizations.of(context)!.done,
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            color: enable
                                ? AppColors.primary400
                                : AppColors.grey300)));
              })
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
        final title =
            SharedFuncs.translateAutoDeletionSettingTime(time, context);

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

    _enableDoneBtn.value = _selectedTime != widget.initExpTime;
  }

  void _onSubmit() async {
    _isUpdating.value = true;
    try {
      final success = await widget.onSubmit(_selectedTime);
      if (success) {
        Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      App.logger.severe(e);
    }

    _isUpdating.value = false;
    await showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.networkError,
        content: AppLocalizations.of(context)!.networkErrorDes,
        actions: [
          AppAlertDialogAction(
            text: AppLocalizations.of(context)!.ok,
            action: () => Navigator.of(context).pop(),
          )
        ]);
  }
}
