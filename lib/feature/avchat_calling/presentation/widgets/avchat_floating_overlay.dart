import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';

import 'avchat_status_text.dart';

class AvchatFloatingOverlay extends StatefulWidget {
  final double size = 64;

  const AvchatFloatingOverlay({Key? key}) : super(key: key);

  @override
  State<AvchatFloatingOverlay> createState() => _AvchatFloatingOverlayState();
}

class _AvchatFloatingOverlayState extends State<AvchatFloatingOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
          color: Colors.grey.shade400, borderRadius: BorderRadius.circular(8)),
      child: _buildContents(),
    );
  }

  Widget _buildContents() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.audio, size: 28, color: Colors.grey.shade800),
          SizedBox(height: 4),
          Flexible(
            child: AvchatStatusText(),
          )
        ],
      ),
    );
  }
}
