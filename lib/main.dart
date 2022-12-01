import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'src/config/globals.dart';
import 'src/providers/socket_conn.dart';
import 'src/providers/terminal_provider.dart';
import 'src/config/sng_manager.dart';
import 'src/pages/logo_and_actions.dart';
import 'src/pages/my_app.dart';
import 'src/services/get_paths.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  sngManager();
  Size wsize = WidgetsBinding.instance.window.physicalSize;

  final globals = getSngOf<Globals>();
  Size tam = await GetPaths.screen(set: '${wsize.width} ${wsize.height}');
  if(tam.width > wsize.width) {
    globals.sizeWin = tam;
  }else{
    globals.sizeWin = wsize;
  }
  final wmn = globals.sizeWin.width * globals.widMax;
  final h = globals.heiMax;

  doWhenWindowReady(() async {

    appWindow.title = "HARBI";
    appWindow.size   = Size(wmn, h);
    appWindow.maxSize = Size(wmn, h);
    appWindow.minSize = Size(wmn, h);
    appWindow.alignment = Alignment.bottomRight;
    appWindow.show();
  });

  runApp(const Harbi());
}

///
class Harbi extends StatelessWidget {

  const Harbi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    const borderColor = Color.fromARGB(255, 0, 0, 0);

    return MaterialApp(
      title: 'HARBI',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: WindowBorder(
          color: borderColor,
          width: 0,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => TerminalProvider()),
              ChangeNotifierProvider(create: (context) => SocketConn())
            ],
            child: Row(
              children: [
                const Expanded(
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
