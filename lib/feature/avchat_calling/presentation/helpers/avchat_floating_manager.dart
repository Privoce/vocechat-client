import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/avchat_bloc.dart';
import '../widgets/avchat_floating_overlay.dart';

class AvchatFloatingManager {
  static Offset? _offset;
  static OverlayEntry? _overlayEntry;

  static const double _defaultLeftOffset = 16;

  static bool _isDragging = false;

  static bool _isOnScreen = false;

  static void showOverlay(BuildContext context) {
    if (_isOnScreen) {
      return;
    }
    // the floating window size is 64, and the point should be at the center, so
    // the offset is set as 32.
    const double positionOffset = 32;
    final topOffset = MediaQuery.of(context).padding.top;

    _offset ??= Offset(_defaultLeftOffset, topOffset);

    _overlayEntry = OverlayEntry(builder: (context) {
      return AnimatedPositioned(
          duration: _isDragging
              ? Duration(microseconds: 0)
              : Duration(milliseconds: 100),
          top: _offset!.dy,
          left: _offset!.dx,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              context.read<AvchatBloc>().add(
                  AvchatMinimizeRequest(toMinimize: false, context: context));
            },
            child: GestureDetector(
                onPanDown: (_) {
                  _isDragging = true;
                },
                onPanUpdate: (details) {
                  _isDragging = true;
                  _offset = Offset(details.globalPosition.dx - positionOffset,
                      details.globalPosition.dy - positionOffset);
                  _overlayEntry?.markNeedsBuild();
                },
                onPanEnd: (details) {
                  _isDragging = false;
                  _adjustPosition(context);
                },
                child: AvchatFloatingOverlay()),
          ));
    });

    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);

      _isOnScreen = true;
    }
  }

  static void _adjustPosition(BuildContext context) {
    const double positionOffset = 32;
    const double horizontalOffset = _defaultLeftOffset + positionOffset;

    final screenSize = MediaQuery.of(context).size;

    final topOffset = MediaQuery.of(context).padding.top + positionOffset;
    final bottomOffset = MediaQuery.of(context).padding.bottom + positionOffset;

    double adjustedX;
    double adjustedY;

    if (_offset!.dx < horizontalOffset || _offset!.dx < screenSize.width / 2) {
      adjustedX = horizontalOffset - positionOffset;
    } else if (_offset!.dx > screenSize.width - horizontalOffset ||
        _offset!.dx >= screenSize.width / 2) {
      adjustedX = screenSize.width - horizontalOffset - positionOffset;
    } else {
      adjustedX = _offset!.dx;
    }

    if (_offset!.dy < topOffset) {
      adjustedY = topOffset - positionOffset;
    } else if (_offset!.dy > screenSize.height - bottomOffset) {
      adjustedY = screenSize.height - bottomOffset - positionOffset;
    } else {
      adjustedY = _offset!.dy;
    }

    _offset = Offset(adjustedX, adjustedY);
    _overlayEntry?.markNeedsBuild();
  }

  static void removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOnScreen = false;
  }
}
