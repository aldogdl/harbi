import 'package:flutter/material.dart';
import 'package:harbi/src/librerias/b_check_file_sys/binarios_harbi_zip.dart';
import 'package:provider/provider.dart';

import '../../librerias/b_check_file_sys/files_ex.dart';
import '../../librerias/b_check_file_sys/make_rutas.dart';
import '../../librerias/b_check_file_sys/my_paths.dart';
import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';
import '../../services/task_from_server.dart';
import '../../providers/terminal_provider.dart';

class CheckFileSys extends StatefulWidget {

  const CheckFileSys({Key? key}) : super(key: key);

  @override
  State<CheckFileSys> createState() => _CheckFileSysState();
}

class _CheckFileSysState extends State<CheckFileSys> {

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
      children: acc.map((e) =>TxtTerminal(
        acc: e, lenTxt: context.read<TerminalProvider>().lenTxt,
      )).toList(),
    );
  }

  ///
  Future<void> _initWidget(_) async {

    final tprod = Provider.of<TerminalProvider>(context, listen: false);
    tprod.accs = [];
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    tprod.setAccs('Sistema de Archivos >_');
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    await Future.delayed(const Duration(milliseconds: 2000));

    tprod.setAccs('> Revisando Sistema de Archivos');
    await MyPaths.crear(tprod);
    if(tprod.accs.last.startsWith('[X]')) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 250));

    tprod.setAccs('> Creando archivos Extras');
    await Future.delayed(const Duration(milliseconds: 250));
    await FilesEx.crear();

    tprod.setAccs('> Creando Estaciones y Status');
    await Future.delayed(const Duration(milliseconds: 250));
    bool upload = await MakeRutas.crear();
    
    if(upload) {
      tprod.setAccs('> Subiendo Rutas a LOCAL');
      await TaskFromServer.uploadRutaTo('local');
      tprod.setAccs('> Subiendo Rutas a REMOTO');
      await TaskFromServer.uploadRutaTo('remoto');
    }

    tprod.setAccs('> Revisando Archivos Binarios');
    await Future.delayed(const Duration(milliseconds: 250));
    String make = await BinariosHarbi.check();
    tprod.setAccs(make);

    tprod.secc = 'configInit';
  }
}