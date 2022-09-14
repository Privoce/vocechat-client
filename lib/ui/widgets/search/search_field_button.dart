import 'package:flutter/material.dart';

class SearchFieldButton extends StatelessWidget implements PreferredSizeWidget {
  final String? hintText;
  final VoidCallback? onTap;

  SearchFieldButton({this.hintText, this.onTap});

  @override
  Size get preferredSize => Size(double.maxFinite, 36);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
        // padding: EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
            color: Color.fromRGBO(118, 118, 128, 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          child: Center(
            child: TextField(
                enabled: false,
                maxLines: 1,
                decoration: InputDecoration(
                    icon: Icon(
                      Icons.search,
                      size: 24,
                    ),
                    isDense: true,
                    hintText: hintText,
                    hintMaxLines: 1,
                    hintStyle: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Color.fromRGBO(60, 60, 67, 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4),
                    contentPadding: EdgeInsets.only(left: 0, right: 10),
                    border: InputBorder.none)),
          ),
        ),
      ),
    );
  }
}
