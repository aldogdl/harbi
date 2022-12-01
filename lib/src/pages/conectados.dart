import 'package:flutter/material.dart';
import 'package:harbi/src/providers/socket_conn.dart';
import 'package:provider/provider.dart';

import '../config/globals.dart';
import '../config/sng_manager.dart';
import '../config/my_theme.dart';
import '../entity/conectado.dart';
import '../providers/terminal_provider.dart';

class Conectados extends StatelessWidget {

  const Conectados({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final globals = getSngOf<Globals>();
  
    return Container(
      padding: const EdgeInsets.all(8),
      color: MyTheme.bgSec,
      child: Selector<SocketConn, bool>(
        selector: (_, prov) => prov.refreshConectados,
        builder: (_, val, child) {

          return (globals.conectados.isEmpty) ? child! : _lst(globals.conectados);
        },
        child: _sinConn(),
      )
    );
  }

  ///
  Widget _sinConn() {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Selector<TerminalProvider, bool>(
        selector: (_, prov) => prov.isPausado,
        builder: (_, value, __) {

          final logo = (value) ? 'logo_dark' : 'logo';
          return Image(
            image: AssetImage('assets/$logo.png'),
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }

  ///
  Widget _lst(List<Conectado> conn) {

    return ListView.builder(
      controller: ScrollController(),
      itemCount: conn.length,
      itemBuilder: (_, int inx) => _conectado(conn[inx].toConectados()),
    );
  }

  ///
  Widget _conectado(Map<String, dynamic> c) {

    const sp = SizedBox(width: 8);
    List<String> prefix = ['Ing.', 'Lic.', 'Sr.', 'Sra.'];
    String name = c['name'];
    for (var i = 0; i < prefix.length; i++) {
      if(name.startsWith(prefix[i])) {
        name = name.replaceFirst(prefix[i], '').trim();
        break;
      }
    }
    if(name.length > 14) {
      name = name.substring(0, 14);
      name = '$name...';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.double_arrow_sharp, size: 10, color: Color.fromARGB(255, 98, 112, 119)),
              const SizedBox(width: 5),
              _texto(name),
              sp,
              _texto(c['app'], color: MyTheme.txtOrange),
              const Spacer(),
              _texto(c['idCon'], color: const Color.fromARGB(255, 148, 148, 148)),
            ],
          ),
          if(c['app'] == 'SCM')
            const Divider(height: 3, color: Colors.orange)
        ],
      )
    );
  }

  ///
  Widget _texto(String texto, {Color color = MyTheme.txtMain}) {

    return Text(
      texto,
      textScaleFactor: 1,
      style: TextStyle(
        color: color,
        fontSize: 13
      ),
    );
  }

}