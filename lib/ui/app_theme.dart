// import 'package:flutter/material.dart';

// class AppTheme {
//   ThemeData get themeData {
//     /// Create a TextTheme and ColorScheme, that we can use to generate ThemeData
//     TextTheme txtTheme =
//         (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
//     Color txtColor = txtTheme.bodyText1.color;
//     ColorScheme colorScheme = ColorScheme(
//         // Decide how you want to apply your own custom them, to the MaterialApp
//         brightness: isDark ? Brightness.dark : Brightness.light,
//         primary: accent1,
//         primaryVariant: accent1,
//         secondary: accent1,
//         secondaryVariant: accent1,
//         background: bg1,
//         surface: bg1,
//         onBackground: txtColor,
//         onSurface: txtColor,
//         onError: Colors.white,
//         onPrimary: Colors.white,
//         onSecondary: Colors.white,
//         error: Colors.red.shade400);

//     /// Now that we have ColorScheme and TextTheme, we can create the ThemeData
//     var t = ThemeData.from(textTheme: txtTheme, colorScheme: colorScheme)
//         // We can also add on some extra properties that ColorScheme seems to miss
//         .copyWith(
//             buttonColor: accent1,
//             cursorColor: accent1,
//             highlightColor: accent1,
//             toggleableActiveColor: accent1);

//     /// Return the themeData which MaterialApp can now use
//     return t;
//   }
// }
