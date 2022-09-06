import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';
import '../../librerias/c_config_init/socket_server.dart';
import '../../services/task_from_server.dart';
import '../../providers/terminal_provider.dart';

class ConfigInit extends StatefulWidget {

  const ConfigInit({Key? key}) : super(key: key);

  @override
  State<ConfigInit> createState() => _ConfigInitState();
}

class _ConfigInitState extends State<ConfigInit> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return TerminalSkel(
      child: Selector<TerminalProvider, List<String>>(
        selector: (_, prov) => prov.accs,
        builder: (context, accs, __) => _lstAcc(accs)
      ),
    );
  }

  ///
  Widget _lstAcc(List<String> acc) {

    return ListView(
      controller: ScrollController(),
      children: acc.map((e) => TxtTerminal(
        acc: e, lenTxt: context.read<TerminalProvider>().lenTxt,
      )).toList(),
    );
  }

  ///
  Future<void> _initWidget(_) async {

    final tprod = Provider.of<TerminalProvider>(context, listen: false);
    tprod.accs = [];
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    tprod.setAccs('Configuración Inicial >_');
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    await Future.delayed(const Duration(milliseconds: 2000));

    tprod.setAccs('> Recuperando datos Iniciales');
    await TaskFromServer.down(tprod);

    tprod.setAccs('Creando SOCKET Y SERVIDOR');
    await Future.delayed(const Duration(milliseconds: 250));
    SocketServer().create();

    tprod.setAccs('> Subiendo datos de conexión');
    await Future.delayed(const Duration(milliseconds: 250));
    await TaskFromServer.upDataConnection();

    tprod.secc = 'socket';
  }

}