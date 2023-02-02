import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Forces portrait-only mode application-wide
/// Use this Mixin on the main app widget i.e. app.dart
/// Flutter's 'App' has to extend Stateless widget.
///
/// Call `super.build(context)` in the main build() method
/// to enable portrait only mode
mixin PortraitModeMixin on StatelessWidget {
  @override
  Widget build(BuildContext context) {
    portraitOnly();
    return super.build(context);
  }
}

mixin LandscapeModeMixin on StatelessWidget {
  @override
  Widget build(BuildContext context) {
    enableLandscape();
    return super.build(context);
  }
}

/// Forces portrait-only mode on a specific screen
/// Use this Mixin in the specific screen you want to
/// block to portrait only mode.
///
/// Call `super.build(context)` in the State's build() method
/// and `super.dispose();` in the State's dispose() method
mixin PortraitStatefulModeMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    portraitOnly();
    super.initState();
  }

  @override
  void dispose() {
    enableLandscape();
    super.dispose();
  }
}

mixin LandscapeStatefulModeMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    enableLandscape();
    super.initState();
  }

  @override
  void dispose() {
    portraitOnly();
    super.dispose();
  }
}

/// blocks rotation; sets orientation to: portrait
void portraitOnly() {
  print("portraitOnly");
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

void enableLandscape() async {
  print("enableLanscape");
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  // ]);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}
