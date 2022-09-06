import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../config/my_theme.dart';

class WinBotones extends StatefulWidget {
  const WinBotones({Key? key}) : super(key: key);

  @override
  State<WinBotones> createState() => _WinBotonesState();
}

class _WinBotonesState extends State<WinBotones> {

  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        MinimizeWindowButton(colors: MyTheme.buttonColors),
        CloseWindowButton(colors: MyTheme.closeButtonColors),
      ],
    );
  }
}
