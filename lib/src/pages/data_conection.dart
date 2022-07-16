import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/sng_manager.dart';
import '../config/globals.dart';
import '../config/my_theme.dart';
import '../providers/socket_conn.dart';

class DataConection extends StatelessWidget {

  const DataConection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final globals = getSngOf<Globals>();

    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          _texto(
            'Herramienta AUTOPARNET, Revisión Bidireccional Inteligente',
            color: const Color.fromARGB(255, 4, 153, 108),
            isCenter: true
          ),
          const Divider(height: 10, color: Colors.grey),
          if(context.watch<SocketConn>().isConnectedSocked)
            ...[
              _row('Mi IP:', '${globals.ipHarbi}:${globals.portHarbi}'),
              _row('B.D. Local:', globals.bdLocal),
              _row('SIDD:', globals.wifiName),
            ]
          else
            _texto(
              'Administra conexiones, cambios en el servidor '
              'y comunica a sus miembros.',
              isCenter: true
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
          const Icon(Icons.circle, size: 8, color: MyTheme.txtOrange),
          const SizedBox(width: 5),
          _texto(label),
          const Spacer(),
          _texto(value, color: Colors.green),
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
}