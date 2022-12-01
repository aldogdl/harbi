import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../librerias/b_check_file_sys/my_paths.dart';
import '../../providers/terminal_provider.dart';
import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';

class FileSysInit extends StatefulWidget {

  const FileSysInit({Key? key}) : super(key: key);

  @override
  State<FileSysInit> createState() => _FileSysInitState();
}

class _FileSysInitState extends State<FileSysInit> {

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

    final tprod = context.read<TerminalProvider>();
    tprod.accs = [];
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    tprod.setAccs('Creando Sistema de Archivos >_');
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));

    await MyPaths.crearInit(tprod);
    if(tprod.accs.last.startsWith('[X]')) {
      return;
    }
    
    if(tprod.secc == 'initShell') {
      tprod.secc = '0';
      Future.microtask(() {
        tprod.secc = '0';
      });
    }else{
      tprod.secc = 'initShell';
    }
  }
}