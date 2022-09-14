import 'package:flutter/material.dart';

class FullWidthTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final double height;
  final bool enableMargin;
  final bool enableDeco;
  final double borderRadius;
  final double fontSize;
  final EdgeInsets scrollPadding;
  final void Function(String)? onChanged;

  const FullWidthTextField(this.controller,
      {Key? key,
      this.focusNode,
      this.onSubmitted,
      this.keyboardType,
      this.textInputAction,
      this.obscureText = false,
      this.height = 50,
      this.enableMargin = true,
      this.enableDeco = true,
      this.borderRadius = 8,
      this.fontSize = 16,
      this.scrollPadding = const EdgeInsets.all(20.0),
      this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      controller: controller,
      focusNode: focusNode,
      autocorrect: false,
      autofocus: true,
      obscureText: obscureText,
      textInputAction: textInputAction,
      textAlignVertical: TextAlignVertical.center,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      scrollPadding: scrollPadding,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
