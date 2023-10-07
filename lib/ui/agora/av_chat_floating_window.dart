import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class AvChatFloatingWindow extends StatefulWidget {
  const AvChatFloatingWindow({super.key});

  @override
  State<AvChatFloatingWindow> createState() => _AvChatFloatingWindowState();
}

class _AvChatFloatingWindowState extends State<AvChatFloatingWindow> {
  final double width = 100;
  final double height = 100;

  double _xPos = 0;
  double _yPos = 0;

  // Finger position within the floating window when dragging starts,
  // value is the difference between finger position and the top left corner of the widget
  // double _xOffset = 0;
  // double _yOffset = 0;

  @override
  Widget build(BuildContext context) {
    // final topOffset = MediaQuery.of(context).padding.top;
    // final bottomOffset = MediaQuery.of(context).padding.bottom;
    // const leftOffset = 8, rightOffset = 8;

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanStart: (details) {
          // take note of finger position offset to the topleft corner of the widget
        },
        onPanUpdate: (details) {
          setState(() {
            _xPos = details.globalPosition.dx - width / 2;
            _yPos = details.globalPosition.dy - height / 2;
          });
        },
        child: Container(
          width: width,
          height: height,
          color: AppColors.primaryBlue,
          child: Center(
            child: Text(
              'Floating Window',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updatePos(DragUpdateDetails details, EdgeInsets safeAreaPadding) {
    setState(() {
      _xPos = details.globalPosition.dx;
      _yPos = details.globalPosition.dy;
    });
  }
}

class FloatingWindowOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context) {
    _overlayEntry?.remove();
    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (context) => AvChatFloatingWindow());
    overlayState.insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
