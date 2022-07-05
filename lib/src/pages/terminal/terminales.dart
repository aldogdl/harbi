import 'package:flutter/material.dart';
import 'package:harbi/src/pages/terminal/cron_centinela.dart';
import 'package:harbi/src/pages/terminal/down_centinela.dart';
import 'package:provider/provider.dart';

import 'init_harbi.dart';
import 'check_system.dart';
import 'conect_socket.dart';
import '../../providers/terminal_provider.dart';

class Terminales extends StatelessWidget {

  const Terminales({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Selector<TerminalProvider, String>(
      selector: (_, prov) => prov.secc, 
      builder: (_, secc, __) => _getSegunSeccion(secc)
    );
  }

  ///
  Widget _getSegunSeccion(String secc) {

    switch (secc) {
      case 'check':
        return const CheckSystem();
      case 'init':
        return const InitHarbi();
      case 'socket':
        return const ConectSocket();
      case 'downCent':
        return const DownCentinela();
      case 'cron':
        return const CronCentinela();
      default:
        return const SizedBox();
    }
  }
}