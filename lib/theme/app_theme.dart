import 'package:flutter/material.dart';

class AppTheme {
  /// Amarillo corporativo (#F6D511). Es el amarillo del logo: cualquier
  /// superficie de marca del app sale de acá.
  ///
  /// No confundir con los amarillos semanticos (`Colors.amber` para estados
  /// pendientes, dorado para estrellas de calificacion): esos comunican otra
  /// cosa y no siguen a la marca.
  static const Color primary = Color(0xFFF6D511);

  /// Alias historico de [primary]. Se mantiene para no romper las pantallas
  /// que ya lo referencian; ambos son el mismo color.
  static const Color brandYellow = primary;
  static const Color btnColor = Color.fromRGBO(122, 161, 140, 1);
  static const Color secondary = Color.fromARGB(255, 0, 0, 0);
  static const Color title = Color.fromARGB(255, 0, 148, 94);
  static const Color bgContacto = Color.fromRGBO(0, 148, 94, 1);
  static const Color bg = Colors.white;
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    //color primario
    primaryColor: bg,
    scaffoldBackgroundColor: bg,
    //appBar theme
    appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
  );
}
