import 'package:flutter/material.dart';
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

    tprod.setAccs('> Buscando IP del Sistema');
    await GetIp.search(tprod);
    await Future.delayed(const Duration(milliseconds: 250));

    _checkConnRemota(tprod).then((isOk) async {

      if(isOk) {
        _checkConnLocal(tprod).then((isOk) {
          if(isOk) {
            tprod.secc = 'checkFileSys';
          }
        });
      }
    });
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
  Future<bool> _checkConnLocal(TerminalProvider tprod) async {

    tprod.setAccs('> Check Conexión LOCAL');
    final res = await TestConn.local(tprod);
    if(res.startsWith('ask_')) {
      await _testConIpDelUser('local');
    }
    return await _revisarResult(tprod, 'local');
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
        insetPadding: const EdgeInsets.all(15),
        backgroundColor: MyTheme.bgDark,
        content: body
      )
    );
  }

  ///
  Future<bool?> _testConIpDelUser(String tipo) async {

    return await _showAlert(
      AskByIp(tipo: tipo, tprov: context.read<TerminalProvider>())
    );
  }


}