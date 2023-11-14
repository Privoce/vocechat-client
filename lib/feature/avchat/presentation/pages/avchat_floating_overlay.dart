import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';

class AvchatFloatingOverlay extends StatefulWidget {
  const AvchatFloatingOverlay({Key? key}) : super(key: key);

  @override
  State<AvchatFloatingOverlay> createState() => _AvchatFloatingOverlayState();
}

class _AvchatFloatingOverlayState extends State<AvchatFloatingOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
          color: Colors.grey, borderRadius: BorderRadius.circular(8)),
      child: _buildContents(),
    );
  }

  Widget _buildContents() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(AppIcons.audio),
          SizedBox(height: 4),
          Flexible(
            child: Text("time",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    decoration: TextDecoration.none)),
          )
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secondsLeft = seconds % 60;
    return "$minutes:$secondsLeft";
  }
}
