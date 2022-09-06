import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/sng_manager.dart';
import '../config/globals.dart';
import '../config/my_theme.dart';
import '../providers/socket_conn.dart';
import '../services/get_paths.dart';

class DataConection extends StatefulWidget {

  const DataConection({Key? key}) : super(key: key);

  @override
  State<DataConection> createState() => _DataConectionState();
}

class _DataConectionState extends State<DataConection> {

  final _globals = getSngOf<Globals>();
  late Future _losSize;

  @override
  void initState() {

    _losSize = _getSize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    String loc = '...';
    if(!_globals.bdLocal.contains('_ip_')) {
      Uri uri = Uri.parse(_globals.bdLocal);
      loc = uri.host;
    }

    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ListView(
        padding: const EdgeInsets.only(top: 1),
        children: [
          if(context.watch<SocketConn>().isConnectedSocked)
            ...[
              _row('IP HARBI:', '${_globals.ipHarbi}:${_globals.portHarbi}'),
              _row('B.D. Local:', loc),
              _row('SIDD:', _globals.wifiName),
              _row('Harbi_bins:', 'Versión: ${_globals.harbiBin}')
            ]
          else
            _texto(
              'Herramienta AUTOPARNET, Revisión Bidireccional Inteligente',
              isCenter: true
            ),
          const Divider(height: 10, color: Colors.grey),
          FutureBuilder(
            future: _losSize,
            builder: (_, AsyncSnapshot snap) {
              
              if(snap.connectionState == ConnectionState.done) {
                return Tooltip(
                  message: 'App: ${_globals.sizeWin.width * _globals.widMax} x ${_globals.heiMax}0',
                  child: _row('Dispositivo:', '${_globals.sizeWin.width} x ${_globals.sizeWin.height} pxs.')
                );
              }
              return _row('Dispositivo;', 'Calculando...');
            }
          )
        ],
      ),
    );
  }

  ///
  Widget _row(String label, String value) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Color.fromARGB(255, 98, 112, 119)),
          const SizedBox(width: 5),
          _texto(label),
          const Spacer(),
          _texto(value, color: const Color.fromARGB(255, 148, 148, 148)),
        ],
      ),
    );
  }

  ///
  Widget _texto(
    String texto,
    {Color color = MyTheme.txtMain, bool isCenter = false}
  ) {

    return Text(
      texto,
      textScaleFactor: 1,
      textAlign: (isCenter) ?  TextAlign.center : TextAlign.left,
      style: TextStyle(
        color: color,
        fontSize: 13
      ),
    );
  }

  ///
  Future<void> _getSize() async {

    final snap = await GetPaths.screen();
    const tmp = Size(1280, 720);
    if(snap.width > 0) {
      _globals.sizeWin = snap;
    }else{
      _globals.sizeWin = tmp;
    }
  }

}
