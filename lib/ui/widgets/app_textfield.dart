import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:voce_widgets/voce_widgets.dart';

class AppTextField extends StatelessWidget {
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final bool autofocus;
  final bool enabled;
  final String? header;
  final String? footer;
  final TextInputAction? textInputAction;

  AppTextField(
      {this.hintText,
      this.maxLines = 1,
      this.minLines,
      this.maxLength,
      this.onSubmitted,
      this.onChanged,
      this.controller,
      this.enabled = true,
      this.autofocus = true,
      this.header,
      this.footer,
      this.textInputAction = TextInputAction.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null && header!.isNotEmpty)
          Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(header!,
                  style: TextStyle(
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w500,
                      fontSize: 14))),
        Container(
          color: Colors.white,
          child: TextField(
            enabled: enabled,
            maxLength: maxLength,
            maxLengthEnforcement:
                MaxLengthEnforcement.truncateAfterCompositionEnds,
            maxLines: maxLines,
            minLines: minLines,
            controller: controller,
            autofocus: autofocus,
            textInputAction: textInputAction,
            inputFormatters:
                maxLength != null ? [VoceTextInputFormatter(maxLength!)] : null,
            decoration: InputDecoration(
                isDense: true,
                counterText: "",
                hintText: hintText,
                hintMaxLines: 1,
                hintStyle: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.labelColorLightSec,
                    fontSize: 17,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
            style: TextStyle(
                fontWeight: FontWeight.w400, fontSize: 17, color: Colors.black),
            onSubmitted: onSubmitted,
            onChanged: onChanged,
          ),
        ),
        if (footer != null && footer!.isNotEmpty)
          Padding(
              padding: EdgeInsets.only(left: 16, top: 4, bottom: 8),
              child: Text(footer!,
                  style: TextStyle(
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w400,
                      fontSize: 13))),
      ],
    );
  }
}
