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
      children: [
        MinimizeWindowButton(colors: MyTheme.buttonColors),
        appWindow.isMaximized
        ? RestoreWindowButton(
            colors: MyTheme.buttonColors,
            onPressed: maximizeOrRestore,
          )
        : MaximizeWindowButton(
            colors: MyTheme.buttonColors,
            onPressed: maximizeOrRestore,
          ),
        CloseWindowButton(colors: MyTheme.closeButtonColors),
      ],
    );
  }
}
