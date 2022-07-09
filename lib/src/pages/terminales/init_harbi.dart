import 'package:flutter/material.dart';
import 'package:harbi/src/librerias/changes_misselanius.dart';
import 'package:provider/provider.dart';

import 'terminal_skel.dart';
import 'txt_terminal.dart';
import '../../../socket_server.dart';
import '../../config/my_theme.dart';
import '../../librerias/task_from_server.dart';
import '../../librerias/files_ex.dart';
import '../../librerias/make_rutas.dart';
import '../../librerias/test_conn.dart';
import '../../librerias/my_paths.dart';
import '../../librerias/get_ip.dart';
import '../../providers/terminal_provider.dart';
import '../../widgets/ask_by_ip.dart';

class InitHarbi extends StatefulWidget {

  const InitHarbi({Key? key}) : super(key: key);

  @override
  State<InitHarbi> createState() => _InitHarbiState();
}

class _InitHarbiState extends State<InitHarbi> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initHarbi);
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
  Widget _btnAcc(String label, bool acc, bool focus) {

    Color bg = (label.startsWith('NO'))
      ? MyTheme.bgSec : const Color.fromARGB(255, 66, 126, 68);

    return ElevatedButton(
      autofocus: focus,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(bg)
      ),
      onPressed: () => Navigator.of(context).pop(acc),
      child: Text(
        label,
        textScaleFactor: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: MyTheme.txtMain
        ),
      ),
    );
  }

  ///
  Future<void> _initHarbi(_) async {

    final tprod = Provider.of<TerminalProvider>(context, listen: false);

    tprod.setAccs('> Buscando IP del Sistema');
    await GetIp.search(tprod);
    await Future.delayed(const Duration(milliseconds: 250));

    tprod.setAccs('> Construyendo paths/producción');
    await MyPaths.crear(tprod);
    await Future.delayed(const Duration(milliseconds: 250));

    tprod.setAccs('> Probando Conexiones');
    await TestConn.local(tprod).then((res) async {

      if(res.startsWith('[X]')) {
        await _errDeConexion(res).then((bool? acc) async {
          acc = (acc == null) ? false : acc;
          if(acc) {
            await _probarConIpDelUser('local').then((bool? acc) async {
              acc = (acc == null) ? false : acc;
              if(acc) {
                await _testRemoto(tprod);
              }
            });
          }
        });
      }else{
        await _testRemoto(tprod);
      }
    });

    tprod.setAccs('> Recuperando datos Iniciales');
    await TaskFromServer.down();

    tprod.setAccs('> Creando archivos Extras');
    await Future.delayed(const Duration(milliseconds: 250));
    await FilesEx.crear();

    tprod.setAccs('> Creando rutas y estatus');
    await Future.delayed(const Duration(milliseconds: 250));
    bool upload = await MakeRutas.crear();
    if(upload) {
      tprod.setAccs('> Subiendo Rutas a LOCAL');
      await TaskFromServer.uploadRutaTo('local');
      tprod.setAccs('> Subiendo Rutas a REMOTO');
      await TaskFromServer.uploadRutaTo('remoto');
    }

    tprod.setAccs('Creando SOCKET Y SERVIDOR');
    await Future.delayed(const Duration(milliseconds: 250));
    SocketServer().create();

    tprod.setAccs('> Subiendo datos de conexión');
    await Future.delayed(const Duration(milliseconds: 250));
    await TaskFromServer.upDataConnection();

    tprod.setAccs('> Revisando Misselanius');
    await Future.delayed(const Duration(milliseconds: 250));
    await ChangesMisselanius.check(tprod);

    await Future.delayed(const Duration(milliseconds: 1500));
    tprod.accs = [];
    tprod.secc = 'socket';
  }

  ///
  Future<void> _testRemoto(TerminalProvider tprod) async {

    await TestConn.remota(tprod).then((res) async {

      if(res == 'ok') { return; }

      if(res.startsWith('[X]')) { tprod.setAccs(res); }
      
      await _errDeConexion(res).then((bool? acc) async {
        acc = (acc == null) ? false : acc;
        if(acc) {
          await _probarConIpDelUser('remota');
        }
      });
    });
  }

  ///
  Future<bool?> _errDeConexion(String msg) async {

    return await _showAlert(
      Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '¡UPS! OCURRIO UN ERROR EN LA CONEXIÓN',
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const Divider(color: Colors.grey),
                Text(
                  msg,
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: MyTheme.txtMain
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '¿Deseas intentar colocar una IP valida y Reintentarlo?',
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: MyTheme.txtMain
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _btnAcc('NO, INTENTAR', false, false),
                    const SizedBox(width: 10),
                    _btnAcc('SÍ, INTENTAR', true, true),
                  ],
                ),
              ],
            ),
          )
        ],
      )
    );
  }

  ///
  Future<bool?> _probarConIpDelUser(String tipo) async {

    final tprod = context.read<TerminalProvider>();

    tprod.setAccs('> Solicitando nueva IP');
    return await _showAlert(AskByIp(tipo: tipo, tprov: tprod));
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
}