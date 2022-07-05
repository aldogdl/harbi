import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';

import 'src/providers/socket_conn.dart';
import 'src/providers/terminal_provider.dart';
import 'src/config/sng_manager.dart';
import 'src/pages/logo_and_actions.dart';
import 'src/pages/my_app.dart';

void main() {
  
  sngManager();
  runApp(const Harbi());
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(970.0, 118.0);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.bottomRight;
    win.title = "HARBI";
    win.show();
  });
}


///
class Harbi extends StatelessWidget {

  const Harbi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    const borderColor = Color(0xFF805306);

    return MaterialApp(
      title: 'HARBI',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: WindowBorder(
          color: borderColor,
          width: 1,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => TerminalProvider()),
              ChangeNotifierProvider(create: (context) => SocketConn())
            ],
            child: Row(
              children: const [
                Expanded(
                  child: MyApp()
                ),
                LogoAndActions(),
              ],
            ),
          ),
        ),
      )
    );
  }
}
