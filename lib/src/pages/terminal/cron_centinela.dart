import 'package:flutter/material.dart';
import 'package:harbi/src/librerias/conectados_check.dart';
import 'package:provider/provider.dart';
import 'package:cron/cron.dart';

import 'terminal_skel.dart';
import 'txt_terminal.dart';
import '../../config/my_theme.dart';
import '../../config/sng_manager.dart';
import '../../config/globals.dart';
import '../../entity/request_event.dart';
import '../../librerias/task_from_server.dart';
import '../../librerias/changes_misselanius.dart';
import '../../providers/terminal_provider.dart';
import '../../providers/socket_conn.dart';
import '../../services/get_paths.dart';

class CronCentinela extends StatefulWidget {

  const CronCentinela({Key? key}) : super(key: key);

  @override
  State<CronCentinela> createState() => _CronCentinelaState();
}

class _CronCentinelaState extends State<CronCentinela> {

  final _globals = getSngOf<Globals>();
  late final SocketConn _sock;
  late final TerminalProvider _tprov;

  final ValueNotifier<double> _progressVal = ValueNotifier<double>(0);
  final String _periodo = '*/1 * * * * *';

  Cron _recovery = Cron();

  /// El total de width
  double _wt = 0;
  /// El numero de pixeles que debe recorres el progress
  double _ppx = 0;
  bool _isInit = false;
  String _uri = '';

  
  @override
  void dispose() {
    _recovery.close();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    
    if(!_isInit) {
      _isInit = true;
      _sock = context.read<SocketConn>();
      _tprov = context.read<TerminalProvider>();
      _initWidget();
    }

    return LayoutBuilder(
      builder: (context, constraints) {

        if(_wt == 0) { _wt = constraints.maxWidth; }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: _terminal(),
              ),
              Positioned(
                top: 5, right: 3,
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

    if(_ppx == 0) { _ppx = _wt / _globals.revCada; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        color: MyTheme.bgMain,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5))
      ),
      child: Text(
        '${_globals.revCada}s',
        textScaleFactor: 1,
        style: const TextStyle(
          fontSize: 11, color: Colors.white
        ),
      ),
    );
  }
  
  ///
  Widget _progressTime() {

    return ValueListenableBuilder<double>(
      valueListenable: _progressVal,
      builder: (_, time, __) {
        return Container(
          width: time, height: 3,
          decoration: const BoxDecoration(color: Colors.green),
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
      children: acc.map((e) => TxtTerminal(acc: e)).toList(),
    );
  }

  ///
  Future<void> _initWidget() async {

    if(_uri.isEmpty) {
      _uri = await GetPaths.getUri('check_changes', isLocal: false);
    }
    if(_tprov.requiredNotiff) {
      _tprov.requiredNotiff = false;
      _sendNotificationUpdateData();
    }
    _tprov.setAccs('> Iniciando Monitoreo Continuo');
    await Future.delayed(const Duration(milliseconds: 250));
    _cronStart();
  }

  ///
  Future<void> _cronStart() async {

    try {
      _scheduleTask();
    } catch (e) {
      if(e.toString().contains('Close')) {
        _recovery = Cron();
        await Future.delayed(const Duration(milliseconds: 500));
        _scheduleTask();
      }else{
        _tprov.setAccs('[X] ${e.toString()}');
      }
    }
  }

  ///
  void _scheduleTask() {

    _recovery.schedule(Schedule.parse(_periodo), () async {

      if(_progressVal.value >= _wt) {
        _progressVal.value = 0;
        _revisarServer();
      }else{
        _progressVal.value = (_progressVal.value + _ppx);
      }
    });
  }

  ///
  Future<void> _revisarServer() async {

    if(_globals.versionCentinela.isNotEmpty) {

      if(_tprov.requiredNotiff) {
        _tprov.requiredNotiff = false;
        _sendNotificationUpdateData();
      }

      final ti = DateTime.now();
      final isTime = _tprov.isTime(ti);
      if(isTime >= _globals.revCada) {

        final has = await TaskFromServer.checkCambionEnCentinela(_uri);
        _tprov.lastCheck = ti;
        _tprov.cantChecks = _tprov.cantChecks +1;
        _tprov.setAccs('> ULTIMO CHEQUEO [${ti.day} ${ti.hour}:${ti.minute}:${ti.second} #${_tprov.cantChecks}]');
        _sendNotificationUpdateTime();
        if(has.isNotEmpty) {

          if(has.containsKey('err')) {
            _tprov.setAccs('[X] Error al CHECAR ver. centinela');
          }else{

            if(has.containsKey('misselanius') && has['misselanius']) { ChangesMisselanius.check(_tprov); }

            if(has['centinela']) { _tprov.secc = 'downCent'; }
          }
        }
      }
    }else{
      _globals.versionCentinela = '1';
    }
  }

  ///
  void _sendNotificationUpdateTime() {

    final time = DateTime.now();
    final req = RequestEvent(
      event: 'self', fnc: 'notifAll_UpdateTime', data: {
        'time' : '${time.minute}:${time.second}',
        'vers' : _globals.versionCentinela
      }
    );
    _sock.event = req.toSend();
    _sock.send();
    Future.delayed(const Duration(milliseconds: 3000), (){
      // Revisamos si hay un miembro que no este conectado.
      ConectadosCheck.checarMiembrosConectados(_tprov);
    });
  }

  ///
  void _sendNotificationUpdateData() {

    final req = RequestEvent(
      event: 'self', fnc: 'notifAll_UpdateData', data: {'acc':'recovery'}
    );
    _sock.event = req.toSend();
    _sock.send();
  }

}