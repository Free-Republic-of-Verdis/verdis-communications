import 'package:flutter/material.dart';

class Constants {
  static String appName = "Verdis Communications";

  static const regularHeading = TextStyle(
      fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.black);

  static const boldHeading = TextStyle(
      fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.white);

  static const regularDarkText = TextStyle(
      fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black);

  //Colors for theme
  static Color lightPrimary = const Color(0xfffcfcff);
  static Color darkPrimary = Colors.black;
  static Color lightAccent = Colors.blue;
  static Color darkAccent = Colors.blueAccent;
  static Color lightBG = const Color(0xfffcfcff);
  static Color darkBG = Colors.black;

  static ThemeData lightTheme = ThemeData(
    backgroundColor: lightBG,
    primaryColorLight: darkBG,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBG,
    appBarTheme: AppBarTheme(
      elevation: 0,
      toolbarTextStyle: TextStyle(
        color: darkBG,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: lightAccent),
    textSelectionTheme: TextSelectionThemeData(cursorColor: lightAccent),
  );

  static ThemeData darkTheme = ThemeData(
    backgroundColor: darkBG,
    primaryColorLight: lightBG,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBG,
    appBarTheme: AppBarTheme(
      elevation: 0,
      toolbarTextStyle: TextStyle(
        color: lightBG,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch()
        .copyWith(secondary: darkAccent, brightness: Brightness.dark),
    textSelectionTheme: TextSelectionThemeData(cursorColor: darkAccent),
  );
}
