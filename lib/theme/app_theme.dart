import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color.fromRGBO(254, 236, 56, 1);
  static const Color btnColor = Color.fromRGBO(122, 161, 140, 1);
  static const Color title = Color.fromARGB(255, 0, 148, 94);
  static const Color bgContacto = Color.fromRGBO(0, 148, 94, 1);
  static const Color bg = Colors.white;
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    //color primario
    primaryColor: bg,
    scaffoldBackgroundColor: bg,
    //appBar theme
    appBarTheme: const AppBarTheme(color: bg, elevation: 0),
  );
}
