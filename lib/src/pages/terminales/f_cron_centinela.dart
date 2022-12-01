import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/my_theme.dart';
import '../../config/sng_manager.dart';
import '../../config/globals.dart';
import '../../providers/socket_conn.dart';
import '../../providers/terminal_provider.dart';
import '../../services/get_paths.dart';
import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';

class CronCentinela extends StatefulWidget {

  const CronCentinela({Key? key}) : super(key: key);

  @override
  State<CronCentinela> createState() => _CronCentinelaState();
}

class _CronCentinelaState extends State<CronCentinela> {

  final _globals = getSngOf<Globals>();
  late final TerminalProvider _tprov;

  bool _isInit = false;

  @override
  Widget build(BuildContext context) {
    
    if(!_isInit) {
      _isInit = true;
      _tprov = context.read<TerminalProvider>();
      _initWidget();
    }

    return LayoutBuilder(

      builder: (context, constraints) {

        if(_tprov.wt == 0) { _tprov.wt = constraints.maxWidth; }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: _terminal(),
              ),
              Positioned(
                bottom: 5, right: 3,
                child: _cadaCuando(),
              ),
              Positioned(
                top: 0, left: 0,
                child: _progressTime(),
              )
            ],
          ),
        );
      },
    );
  }

  ///
  Widget _cadaCuando() {

    if(_tprov.ppx == 0) { _tprov.ppx = _tprov.wt / _globals.revCada; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        color: MyTheme.bgMain,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(5))
      ),
      child: Selector<TerminalProvider, int>(
        selector: (_, prov) => prov.progressCount,
        builder: (_, seg, __) {
          return Text(
            'vc: ${_globals.versionCentinela}       $seg/${_globals.revCada}s',
            textScaleFactor: 1,
            style: const TextStyle(
              fontSize: 12, color: Colors.white
            ),
          );
        },
      )
    );
  }
  
  ///
  Widget _progressTime() {

    return Selector<TerminalProvider, double>(
      selector: (_, prov) => prov.progressVal,
      builder: (_, time, __) {
        return Container(
          width: time, height: 3,
          decoration: const BoxDecoration(color: Color.fromARGB(255, 20, 240, 12)),
        );
      }
    );
  }

  ///
  Widget _terminal() {

    return TerminalSkel(
      child: Selector<TerminalProvider, List<String>>(
        selector: (_, prov) => prov.accs,
        builder: (_, accs, __) => _lstAcc(accs),
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
  Future<void> _initWidget() async {

    bool isLoc = (_globals.env == 'dev') ? true : false;
    if(_tprov.uriCheckCron.isEmpty) {
      _tprov.uriCheckCron = await GetPaths.getUri('check_changes', isLocal: isLoc);
    }

    if(mounted) {

      final sock = context.read<SocketConn>();
      await sock.initCheckInPush();
      await Future.delayed(const Duration(milliseconds: 500));

      Future.delayed(const Duration(milliseconds: 500), () {
        _tprov.setIsPausado(false);
        _tprov.cronStart();
      });
    }
  }


}