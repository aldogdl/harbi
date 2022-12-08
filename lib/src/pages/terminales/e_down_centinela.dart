import 'package:flutter/material.dart';
import 'package:harbi/src/services/pushin_build.dart';
import 'package:provider/provider.dart';

import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';
import '../../librerias/f_cron_centinela/changes_misselanius.dart';
import '../../librerias/e_down_centinela/changes_centinela.dart';
import '../../librerias/e_down_centinela/harbi_ftp.dart';
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
      children: acc.map((e) => TxtTerminal(
        acc: e, lenTxt: context.read<TerminalProvider>().lenTxt,
      )).toList(),
    );
  }

  ///
  Future<void> _initDown(_) async {

    final tprod = Provider.of<TerminalProvider>(context, listen: false);
    tprod.accs = [];
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    tprod.setAccs('Descargando Centinela >_');
    tprod.setAccs(''.padRight(tprod.lenTxt, '-'));
    
    tprod.setAccs('> Conectando FTP Centinela');
    final resp = await HarbiFTP.downFile('centinela.json', 'centinela', tprod);
    if(resp == 'err') {
      tprod.setAccs('[X] Archivo Centinela no existe o error en Descarga');
    }else{

      tprod.setAccs('[√] GUARDANOD NUEVA VERSION.');
      await HarbiFTP.setVersionOnGlobals();
      tprod.setAccs('[√] DESCARGA EXITOSA.');
      // Enviar una notificacion a todos de actualizar centinela.
      // al actualizar cada SCP el centinela, solo debe revisar si hay nuevas
      // asignaciones.
      await _pushUpdateMake();
      tprod.setAccs('[√] Enviando Centinela UPDATE.');
      await Future.delayed(const Duration(milliseconds: 3000));

      if(tprod.hasMisselanius) {
        tprod.hasMisselanius = false;
        await ChangesMisselanius.check(tprod);
      }
      
      // Checamos si hay nuevas ordenes para descargar.
      await ChangesCentinela.chek('centinela', HarbiFTP.oldCenti, tprod);
      ChangesCentinela.dispose();
      HarbiFTP.oldCenti = {};
    }

    tprod.waitIsWorking = false;
    tprod.secc = 'cron';
  }

  ///
  Future<void> _pushUpdateMake() async {

    final schema = PushInBuild.getSchemaMain(
      priority: 'baja',
      secc: 'centinela',
      titulo: 'Nueva Versión del CENTINELA FILE',
      descrip: 'Cambio de: ${HarbiFTP.oldCenti['version']} a: ${HarbiFTP.globals.versionCentinela}',
      data: {
        'oldv': HarbiFTP.oldCenti['version'],
        'newv': HarbiFTP.globals.versionCentinela
      }
    );
    PushInBuild.setIn('centinela_update', schema);
    await Future.delayed(const Duration(milliseconds: 350));
  }

}