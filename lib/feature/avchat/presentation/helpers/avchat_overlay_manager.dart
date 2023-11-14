import 'package:flutter/cupertino.dart';
import 'package:vocechat_client/feature/avchat/presentation/pages/avchat_floating_overlay.dart';

class AvchatFloatingOverlayManager {
  static Offset? _offset;
  static OverlayEntry? _overlayEntry;

  static const double _defaultLeftOffset = 16;

  // TODO: add position memory in database (maybe shared preferences)
  static void showOverlay(BuildContext context, {Offset? initialOffset}) {
    final topOffset = MediaQuery.of(context).padding.top;

    _offset ??= Offset(_defaultLeftOffset, topOffset);

    _overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
          top: _offset!.dy,
          left: _offset!.dx,
          child: GestureDetector(
              onPanUpdate: (details) {
                _offset = details.globalPosition;
                _overlayEntry?.markNeedsBuild();
              },
              child: AvchatFloatingOverlay()));
    });

    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  static void removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
