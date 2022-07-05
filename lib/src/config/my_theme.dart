import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart' show Color;

class MyTheme {

  static const bgMain = Color(0xFF323233);
  static const bgMainLigth = Color.fromARGB(255, 87, 87, 87);
  static const bgSec = Color(0xFF252526);
  static const bgDark = Color(0xFF1e1e1e);
  static const txtMain = Color(0xFF81dcfe);
  static const txtOrange = Color(0xFFd6a510);

  static final buttonColors = WindowButtonColors(
    iconNormal: txtMain,
    mouseOver: bgMainLigth,
    mouseDown: bgMainLigth,
    iconMouseOver: txtMain,
    iconMouseDown: txtMain
  );

  static final  closeButtonColors = WindowButtonColors(
    iconNormal: txtMain,
    mouseOver: const Color(0xFFB71C1C),
    mouseDown: const Color(0xFFD32F2F),
    iconMouseOver: txtMain
  );
}