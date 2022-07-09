import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'terminal_skel.dart';
import 'txt_terminal.dart';
import '../../librerias/changes_centinela.dart';
import '../../librerias/harbi_ftp.dart';
import '../../providers/terminal_provider.dart';

class DownCentinela extends StatefulWidget {

  const DownCentinela({Key? key}) : super(key: key);

  @override
  State<DownCentinela> createState() => _DownCentinelaState();
}

class _DownCentinelaState extends State<DownCentinela> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initDown);
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
      children: acc.map((e) => TxtTerminal(acc: e)).toList(),
    );
  }

  ///
  Future<void> _initDown(_) async {

    final tprod = Provider.of<TerminalProvider>(context, listen: false);
    
    tprod.setAccs('> Conectando FTP Centinela');
    final resp = await HarbiFTP.downFile('centinela.json', 'centinela', tprod);
    if(resp == 'err') {
      tprod.setAccs('[X] Archivo Centinela no existe o error en Descarga');
    }else{
      tprod.setAccs('[√] DESCARGA EXITOSA.');
      await ChangesCentinela.chek('centinela', HarbiFTP.oldCenti, tprod);
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    tprod.secc = 'cron';
  }


}