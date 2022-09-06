import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/terminales/b_check_file_sys.dart';
import '../pages/terminales/refresh_systema.dart';
import '../pages/terminales/f_cron_centinela.dart';
import '../pages/terminales/e_down_centinela.dart';
import '../pages/terminales/c_config_init.dart';
import '../pages/terminales/a_init_shell.dart';
import '../pages/terminales/d_conect_socket.dart';
import '../providers/terminal_provider.dart';

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
      case 'refresh':
        return const RefreshSystema();
      case 'initShell':
        return const InitShell();
      case 'checkFileSys':
        return const CheckFileSys();
      case 'configInit':
        return const ConfigInit();
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