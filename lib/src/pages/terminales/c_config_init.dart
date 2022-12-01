import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/my_theme.dart';
import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';
import '../../librerias/c_config_init/socket_server.dart';
import '../../services/get_paths.dart';
import '../../services/task_from_server.dart';
import '../../providers/terminal_provider.dart';

class ConfigInit extends StatefulWidget {

  const ConfigInit({Key? key}) : super(key: key);

  @override
  State<ConfigInit> createState() => _ConfigInitState();
}

class _ConfigInitState extends State<ConfigInit> {

  final _ctrSwh = TextEditingController();
  String _msg = 'Ej. 00#L';

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  void dispose() {
    _ctrSwh.dispose();
    super.dispose();
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

    tprod.setAccs('> Subiendo datos de conexión');
    await Future.delayed(const Duration(milliseconds: 250));

    String res = await TaskFromServer.upDataConnection();
    if(res == 'swh') {
      bool? r = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: MyTheme.bgDark,
          contentPadding: const EdgeInsets.all(5),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          content: StatefulBuilder(
            builder: (BuildContext context, setState) {
              return SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: _getSwh(setState),
              );
            },
          ),
        )
      );
      
      r = (r == null) ? false : r;
      if(r) {
        await TaskFromServer.upDataConnection();
        _conectarSocket(tprod);
      }else{
        await _initWidget(null);
      }

    }else{
      _conectarSocket(tprod);
    }
  }

  ///
  void _conectarSocket(TerminalProvider tprod) async {

    tprod.setAccs('Creando SOCKET Y SERVIDOR');
    await Future.delayed(const Duration(milliseconds: 250));
    SocketServer().create();
    tprod.secc = 'socket';
  }

  ///
  Widget _getSwh(StateSetter st) {

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          )
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Text(
                  'No se ha establecido una clave de Estación de Trabajo',
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MyTheme.txtMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 17
                  ),
                ),
                Text(
                  'Por favor, introduce la clave SWH, para poder continuar.',
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MyTheme.txtMain,
                    fontWeight: FontWeight.normal,
                    fontSize: 15
                  ),
                ),
                Divider(color: Colors.grey),
                Text(
                  'La clave única SWH, es una serie de dígitos que identifican inequivocamente '
                  'a esta estación de tranajo HARBI frente al '
                  'servidor remoto (SR).',
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MyTheme.txtMain,
                    fontWeight: FontWeight.normal,
                    fontSize: 13.5
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _txtBox(),
                const SizedBox(height: 5),
                Text(
                  _msg,
                  textScaleFactor: 1,
                  style: TextStyle(
                    color: (!_msg.startsWith('[X]')) ? Colors.grey : Colors.yellow,
                    fontSize: 12,
                    letterSpacing: 1.2
                  ),
                ),
                const SizedBox(height: 5),
                _btnSave(st)
              ],
            ),
          ),
        )
      ],
    );
  }

  ///
  Widget _txtBox() {

    return TextField(
      controller: _ctrSwh,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.green
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: MyTheme.bgMain,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        border: styleBox(),
        enabledBorder: styleBox(),
        focusedBorder: styleBox(),
      ),
    );
  }

  ///
  Widget _btnSave(StateSetter st) {

    return SizedBox(
      height: 25,
      child: ElevatedButton.icon(
        onPressed: () async {

          final nav = Navigator.of(context);
          Map<String, dynamic> est = await GetPaths.getContentFileOf('harbis');
          if(est.isNotEmpty) {
            if(est['body'].containsKey(_ctrSwh.text.toUpperCase())) {
              final path = await GetPaths.getFileByPath('swh');
              final file = File(path);
              file.writeAsStringSync(_ctrSwh.text.toUpperCase());
              nav.pop(true);
            }else{
              st(() { _msg = '[X] NO Existe...'; });
            }
          }
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.green)
        ),
        icon: const Icon(Icons.workspaces_rounded, size: 18),
        label: const Text(
          'Guardar',
          textScaleFactor: 1,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
      ),
    );
  }

  ///
  OutlineInputBorder styleBox() {

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color.fromARGB(255, 85, 85, 85)),
    );
  }
}