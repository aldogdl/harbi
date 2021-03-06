import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';

import 'src/config/globals.dart';
import 'src/providers/socket_conn.dart';
import 'src/providers/terminal_provider.dart';
import 'src/config/sng_manager.dart';
import 'src/pages/logo_and_actions.dart';
import 'src/pages/my_app.dart';
import 'src/services/get_paths.dart';

void main() {
  
  WidgetsFlutterBinding.ensureInitialized();

  sngManager();
  final globals = getSngOf<Globals>();

  Size wsize = WidgetsBinding.instance.window.physicalSize;
  doWhenWindowReady(() async {

    if(globals.sizeWin.width == 0) {
      globals.sizeWin = await GetPaths.screen(set: '${wsize.width} ${wsize.height}');
    }else{
      globals.sizeWin = await GetPaths.screen();
    }

    final wmn = globals.sizeWin.width * 0.73;
    const h = 118.0;
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
