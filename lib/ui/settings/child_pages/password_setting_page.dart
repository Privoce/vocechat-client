import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:voce_widgets/voce_widgets.dart';

class PasswordSettingPage extends StatefulWidget {
  const PasswordSettingPage({super.key});

  @override
  State<PasswordSettingPage> createState() => _PasswordSettingPageState();
}

class _PasswordSettingPageState extends State<PasswordSettingPage> {
  final ValueNotifier<bool> _isBusy = ValueNotifier(false);
  final ValueNotifier<bool> _enableDoneBtn = ValueNotifier(true);

  final TextEditingController _oldPswdCtlr = TextEditingController();
  final TextEditingController _newPswdCtlr = TextEditingController();
  final TextEditingController _confirmPswdCtlr = TextEditingController();

  final ValueNotifier<bool> _showPswdWarning = ValueNotifier(false);
  final ValueNotifier<bool> _showPswdConfirmWarning = ValueNotifier(false);

  bool isValidPassword = false;
  bool arePswdsSame = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          toolbarHeight: barHeight,
          elevation: 0,
          backgroundColor: AppColors.barBg,
          title: Text(AppLocalizations.of(context)!.changePassword,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge),
          leading: CupertinoButton(
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97),
              onPressed: () => Navigator.pop(context)),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _enableDoneBtn,
              builder: (context, enable, child) {
                if (enable) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(AppLocalizations.of(context)!.done),
                        onPressed: () {}),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            )
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            VoceTextField.filled(
              _oldPswdCtlr,
              autofocus: true,
              title: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(AppLocalizations.of(context)!.oldPassword,
                    style: AppTextStyles.labelMedium),
              ),
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              textInputAction: TextInputAction.next,
              borderRadius: 0,
              scrollPadding: EdgeInsets.only(bottom: 100),
            ),
            SizedBox(height: 28),

            // new password
            VoceTextField.filled(
              _newPswdCtlr,
              autofocus: true,
              title: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(AppLocalizations.of(context)!.newPassword,
                    style: AppTextStyles.labelMedium),
              ),
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              textInputAction: TextInputAction.next,
              borderRadius: 0,
              scrollPadding: EdgeInsets.only(bottom: 100),
              onChanged: (pswd) {
                isValidPassword = pswd.isNotEmpty && pswd.isValidPswd;
                arePswdsSame = pswd.isNotEmpty && pswd == _confirmPswdCtlr.text;

                _showPswdWarning.value = !isValidPassword;
                _enableDoneBtn.value = isValidPassword && arePswdsSame;
              },
            ),
            SizedBox(
                height: 28.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showPswdWarning,
                    builder: (context, showPswdAlert, child) {
                      if (showPswdAlert) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!
                                .passwordRegisterPageInvalidPasswordFormat,
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                )),

            // confirm new password
            VoceTextField.filled(
              _confirmPswdCtlr,
              autofocus: true,
              title: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(AppLocalizations.of(context)!.confirmPassword,
                    style: AppTextStyles.labelMedium),
              ),
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              textInputAction: TextInputAction.done,
              borderRadius: 0,
              scrollPadding: EdgeInsets.only(bottom: 100),
              onChanged: (pswd) {
                arePswdsSame = pswd.isNotEmpty && pswd == _newPswdCtlr.text;

                _showPswdConfirmWarning.value = !arePswdsSame;
                _enableDoneBtn.value = isValidPassword && arePswdsSame;
              },
            ),
            SizedBox(
                height: 28.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showPswdConfirmWarning,
                    builder: (context, showPswdConfirmAlert, child) {
                      if (showPswdConfirmAlert) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!
                                .passwordRegisterPagePasswordNotMatch,
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                )),
          ],
        ));
  }

  void onDone() async {
    if (_isBusy.value) return;

    _isBusy.value = true;
    _enableDoneBtn.value = false;

    final oldPswd = _oldPswdCtlr.text.trim();
    final newPswd = _newPswdCtlr.text.trim();

    final res = await UserApi().changePassword(oldPswd, newPswd);
    if (res.statusCode == 200) {
      // success
    } else {
      // fail.
    }
  }
}
