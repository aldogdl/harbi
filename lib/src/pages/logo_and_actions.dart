import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/globals.dart';
import '../config/sng_manager.dart';
import '../providers/terminal_provider.dart';
import '../config/my_theme.dart';
import '../widgets/win_botones.dart';

class LogoAndActions extends StatelessWidget {

  LogoAndActions({Key? key}) : super(key: key);

  final _globals = getSngOf<Globals>();

  @override
  Widget build(BuildContext context) {
    
    return Container(
      width: 190,
      color: MyTheme.bgSec,
      child: Column(
        children: [
          WindowTitleBarBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: MoveWindow(
                    child: _title(),
                  )
                ),
                const WinBotones()
              ],
            )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _action(
                icon: Icons.refresh, tip: 'Refrescar Sistema',
                fnc: (){
                  final tProv = context.read<TerminalProvider>();
                  tProv.setIsPausado(true);
                  Future.delayed(const Duration(milliseconds: 500), (){
                    tProv.accs = [];
                    tProv.secc = 'refresh';
                  });
                }
              ),
              Selector<TerminalProvider, bool>(
                selector: (_, prov) => prov.isPausado,
                builder: (_, val, __) {

                  IconData ico = (val) ? Icons.play_arrow : Icons.pause;
                  String tip = (val) ? 'Iniciar' : 'Pausar';
                  return _action(
                    icon: ico, tip: tip,
                    fnc: () => context.read<TerminalProvider>().setIsPausado(!val)
                  );
                }
              ),
              _action(
                icon: Icons.search, tip: 'Ping a Conectados',
                fnc: (){}
              ),
              _action(
                icon: Icons.download, tip: 'Descargar Centinela',
                fnc: (){}
              ),
            ],
          ),
        ],
      ),
    );
  }

  ///
  Widget _title() {

    String dev = (_globals.env == 'dev') ? 'dev' : '';

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 10),
      child: Tooltip(
        message: 'Herramienta AUTOPARNET, Revisión Bidireccional Inteligente',
        child: Text.rich(
          TextSpan(
            text: 'HARBI $dev ',
            style: GoogleFonts.comfortaa(
              fontSize: 11,
              height: 1,
              color: (dev.isEmpty)
                ? const Color.fromARGB(255, 168, 173, 175)
                : const Color.fromARGB(255, 255, 223, 82),
              fontWeight: FontWeight.bold
            ),
            children: [
              TextSpan(
                text: ' ${_globals.harbiV}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.amber
                )
              )
            ]
          ),
          textScaleFactor: 1,
        ),
      )
    );
  }

  ///
  Widget _action({
    required Function fnc,
    required IconData icon,
    required String tip,
  }) {

    const colorI = Color.fromARGB(255, 16, 85, 214);

    return IconButton(
      tooltip: tip,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      onPressed: () => fnc(),
      icon: Icon(icon, size: 20, color: colorI),
    );
  }

 }