import 'package:flutter/material.dart';
import 'package:harbi/src/config/globals.dart';
import 'package:harbi/src/config/sng_manager.dart';
import 'package:harbi/src/widgets/multi_conn_ok.dart';
import 'package:provider/provider.dart';

import '../../librerias/a_init_shell/get_ip.dart';
import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';
import '../../config/my_theme.dart';
import '../../widgets/ask_by_ip.dart';
import '../../librerias/a_init_shell/test_conn.dart';
import '../../providers/terminal_provider.dart';

class InitShell extends StatefulWidget {

  const InitShell({Key? key}) : super(key: key);

  @override
  State<InitShell> createState() => _InitShellState();
}

class _InitShellState extends State<InitShell> {

  final List<Map<String, dynamic>> _multiConn = [];

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

    final tprod = context.read<TerminalProvider>();
    final globals = getSngOf<Globals>();

    tprod.accs = [];
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    tprod.setAccs('Iniciando SHELL >_');
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    await Future.delayed(const Duration(milliseconds: 2000));

    _checkConnRemota(tprod).then((isOk) async {

      if(!isOk) {
        tprod.setAccs('[X] NO HAY CONEXIÓN con AUTOPARNET.COM');
        await Future.delayed(const Duration(milliseconds: 1000));
        tprod.setAccs('[!] Probaré con la conexión Local');
        await Future.delayed(const Duration(milliseconds: 3000));
      }

      tprod.setAccs('> Buscando IPs del Sistema');
      Map<String, dynamic> ips = await GetIp.search();

      tprod.setAccs('[ok] Nombre de la RED: ${ips['wifiName']}');
      globals.wifiName = ips['wifiName'];
      await Future.delayed(const Duration(milliseconds: 250));

      final mainConn = List<Map<String, dynamic>>.from(ips['interfaces']);

      if(mainConn.isNotEmpty) {

        if(mainConn.length > 1) {
          tprod.setAccs('[!] Se encontraron MULTIPLES conexiones');
          await Future.delayed(const Duration(milliseconds: 250));
          tprod.setAccs('> Ethernet será la conexión Prioritaria');
          await Future.delayed(const Duration(milliseconds: 250));
        }

        var conInt = mainConn.where(
          (element) => element['interface'].startsWith('Ethernet')
        ).toList();
        
        await _checkConnLocal(conInt, tprod, globals);

        tprod.setAccs('> Checando el Wi-Fi');
        await Future.delayed(const Duration(milliseconds: 250));

        conInt = mainConn.where(
          (element) => element['interface'].startsWith('Wi')
        ).toList();

        await _checkConnLocal(conInt, tprod, globals);
      }

      if(_multiConn.isEmpty) {
        tprod.setAccs('[X] NO HAY CONEXIÓN a AnetDB');
        await _testConIpDelUser('local');
      }else{
        await _multiConnsWithExito(tprod);
      }

      if(globals.ipHarbi.isNotEmpty) {
        tprod.setAccs('[√] HARBI IP: ${globals.ipHarbi} ACTUAL');
        tprod.secc = 'checkFileSys';
      }else{
        tprod.setAccs('[!] y presione Refrescar Sistema.');
        tprod.setAccs('[!] inténte reparar la conexión');
        tprod.setAccs('[!] una conexión local a la RED.');
        tprod.setAccs('[!] HARBI NO puede continuar sin ');
      }
    });
  }

  ///
  Future<void> _checkConnLocal
    (List<Map<String, dynamic>> conInt, TerminalProvider tprod, Globals globals) async
  {

    String res = 'bad';
    if(conInt.isNotEmpty) {
      for (var i = 0; i < conInt.length; i++) {
        globals.ipHarbi = conInt[i]['ip'];
        res = await TestConn.local(tprod);
        if(res == 'ok') {
          _multiConn.add(conInt[i]);
        }
      }
    }

    globals.ipHarbi = '';
    globals.typeConn = '';

    return;
  }

  ///
  Future<bool> _checkConnRemota(TerminalProvider tprod) async {

    tprod.setAccs('> Check Conexión REMOTA');
    String res = await TestConn.remota(tprod);

    if(res.startsWith('ask_')) {
      await _testConIpDelUser('remoto');
    }
    return await _revisarResult(tprod, 'remoto');
  }

  ///
  Future<bool> _revisarResult(TerminalProvider tprod, String tipo) async {
    
    if(tprod.accs.first.startsWith('[X]')) {
      tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
      tprod.setAccs('[!] Refresca el Sistema por favor');
      tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
      return false;
    }
    return true;
  }

  ///
  Future<bool?> _showAlert(Widget body) async {

    return await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        actionsPadding: const EdgeInsets.all(0),
        contentPadding: const EdgeInsets.all(8),
        insetPadding: const EdgeInsets.all(8),
        backgroundColor: MyTheme.bgDark,
        content: body
      )
    );
  }

  ///
  Future<bool?> _multiConnsWithExito(TerminalProvider tprov) async {

    return await _showAlert(
      MultiConnsOk(conns: _multiConn, tprov: tprov)
    );
  }

  ///
  Future<bool?> _testConIpDelUser(String tipo) async {

    return await _showAlert(
      AskByIp(tipo: tipo, tprov: context.read<TerminalProvider>())
    );
  }


}