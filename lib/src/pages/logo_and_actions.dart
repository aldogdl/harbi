import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:harbi/src/providers/terminal_provider.dart';
import 'package:provider/provider.dart';

import '../config/my_theme.dart';
import '../widgets/win_botones.dart';

class LogoAndActions extends StatelessWidget {

  const LogoAndActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return Container(
      width: 190,
      color: MyTheme.bgSec,
      child: Column(
        children: [
          WindowTitleBarBox(
            child: Row(
              children: [
                Expanded(
                  child: MoveWindow()
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
                  tProv.accs = [];
                  tProv.secc = 'check';
                }
              ),
              _action(
                icon: Icons.cleaning_services_outlined, tip: 'Limpiar Consola',
                fnc: (){}
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
          const Spacer(),
          const Text(
            'HARBI',
            textScaleFactor: 0.8,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 50,
              height: 1,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
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