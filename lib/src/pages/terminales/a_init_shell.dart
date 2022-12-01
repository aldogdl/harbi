import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../config/my_theme.dart';
import '../../librerias/a_init_shell/get_ip.dart';
import '../../librerias/a_init_shell/test_conn.dart';
import '../../services/get_paths.dart';
import '../../providers/terminal_provider.dart';
import '../../widgets/multi_conn_ok.dart';
import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';
import '../../widgets/ask_by_ip.dart';

class InitShell extends StatefulWidget {

  const InitShell({Key? key}) : super(key: key);

  @override
  State<InitShell> createState() => _InitShellState();
}

class _InitShellState extends State<InitShell> {

  final List<Map<String, dynamic>> _multiConn = [];
  final globals = getSngOf<Globals>();

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

    tprod.accs = [];
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    tprod.setAccs('Iniciando SHELL >_');
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    await Future.delayed(const Duration(milliseconds: 2000));

    _checkConnRemota(tprod).then((isOk) async {

      final tprod = context.read<TerminalProvider>();

      if(!isOk) {
        tprod.setAccs('[X] NO HAY CONEXIÓN con AUTOPARNET.COM');
        await Future.delayed(const Duration(milliseconds: 1000));
        tprod.setAccs('[!] Probaré con la conexión Local');
        await Future.delayed(const Duration(milliseconds: 2750));
      }

      tprod.setAccs('> Buscando IPs del Sistema');
      await Future.delayed(const Duration(milliseconds: 250));

      Map<String, dynamic> ips = await GetIp.search();

      tprod.setAccs('[ok] Nombre de la RED: ${ips['wifiName']}');
      globals.wifiName = ips['wifiName'];
      await Future.delayed(const Duration(milliseconds: 250));

      if(ips.containsKey('recovery')) {
        globals.ipHarbi = ips['recovery']['local'];
        final res = await TestConn.local(tprod);
        globals.ipHarbi = '';
        if(res == 'ok') {
          globals.ipHarbi  = ips['recovery']['ipHarbi'];
          globals.typeConn = ips['recovery']['typeConx'];
          globals.bdRemota = ips['recovery']['remoto'];
          globals.bdLocal  = ips['recovery']['local'];
          tprod.setAccs('[√] HARBI IP: ${globals.ipHarbi} ACTUAL');
          tprod.secc = 'checkFileSys';
          return;
        }
        if(!ips.containsKey('interfaces')) {
          tprod.setAccs('[X] NO HAY CONEXIÓN A SL.');
          await Future.delayed(const Duration(milliseconds: 1000));
          return;
        }
      }

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
        // A esta altura todas las conexiones encontradas en la variable 
        // _multiConn ya estan probadas y aprobadas, por lo tanto, solo es
        // necesario que el usuario seleccione la adecuada.
        if(_multiConn.length > 1) {
          await _multiConnsWithExito(tprod);
        }else{
          globals.ipHarbi  = _multiConn.first['ip'];
          globals.typeConn = _multiConn.first['interface'];
          globals.bdLocal  = 'http://${globals.ipHarbi}:${globals.portdb}/${GetPaths.package}/public_html/';
        }
      }

      if(globals.ipHarbi.isNotEmpty) {
        await GetPaths.setDataConectionLocal();
        tprod.setAccs('[√] HARBI IP: ${globals.ipHarbi} ACTUAL');
        await Future.delayed(const Duration(milliseconds: 500));
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