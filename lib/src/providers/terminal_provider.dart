import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:cron/cron.dart';

import '../config/globals.dart';
import '../config/sng_manager.dart';
import '../librerias/f_cron_centinela/changes_misselanius.dart';
import '../services/task_from_server.dart';

class TerminalProvider extends ChangeNotifier {

  final _globals = getSngOf<Globals>();

  Cron _recovery = Cron();

  // La longitud de los caracteres para la terminal
  int lenTxt = 38;
  
  int cantChecks = 0;
  DateTime lastCheck = DateTime.now();

  ///
  int isTime(DateTime now) {
    final diff = now.difference(lastCheck);
    return diff.inSeconds;
  }

  ///
  String _secc = 'fileSysInit';
  String get secc => _secc;
  set secc(String seccion) {
    _secc = seccion;
    notifyListeners();
  }

  List<String> accs = [];
  void setAccs(String accsion) {
    var tmp = List<String>.from(accs);
    String isNotif = '';
    if(tmp.length > 29) {
      if(tmp.first.startsWith('[^]')) {
        isNotif = tmp.first;
      }
      tmp = [];
    }
    accs = [];
    tmp.insert(0, accsion);
    if(isNotif.isNotEmpty) {
      tmp.add(isNotif);
    }
    accs = List<String>.from(tmp);
    tmp = [];
    try {
      notifyListeners();
    } catch (_) {}
  }

  /// El total de width
  double wt = 0;
  /// El numero de pixeles que debe recorres el progress
  double ppx = 0;
  bool isLockCron = false;

  ///
  String uriCheckCron = '';
  /// Usada para pausar el chequeo del cron
  bool isPausado = false;
  void setIsPausado(bool pausa) {
    isPausado = pausa;
    if(isPausado) {
      isLockCron = false;
      _recovery.close();
    }else{
      cronStart();
    }
    notifyListeners();
  }
  
  double _progressVal = 0;
  double get progressVal => _progressVal;
  set progressVal(double val) {
    _progressVal = val;
    notifyListeners();
  }

  int _progressCount = 0;
  int get progressCount => _progressCount;
  set progressCount(int val) {
    _progressCount = val;
    notifyListeners();
  }
  
  /// Para saber si es necesario checar filtros, resp, see, etc
  bool hasMisselanius = false;
  bool waitIsWorking  = false;

  ///
  Future<void> cronStart() async {

    if(isLockCron){ return; }
    isLockCron = true;

    try {
      _scheduleTask();
    } catch (e) {
      if(e.toString().contains('Close')) {
        _recovery = Cron();
        isLockCron = false;
        await Future.delayed(const Duration(milliseconds: 500));
        cronStart();
      }else{
        setAccs('[X] ${e.toString()}');
      }
    }
  }

  ///
  void _scheduleTask() {

    _recovery.schedule(Schedule.parse('*/1 * * * * *'), () async {    

      if(progressVal >= wt) {
        progressVal = 0;
        progressCount = 0;
        _revisarServer();
      }else{
        progressVal = (progressVal + ppx);
        progressCount++;
      }
    });
  }

  ///
  Future<void> _revisarServer() async {

    if(waitIsWorking){ return; }
    String pad(String val) => val.padLeft(2, '0');

    if(_globals.versionCentinela.isNotEmpty) {

      final ti = DateTime.now();
      final isTimeN = isTime(ti);
      if(isTimeN >= _globals.revCada) {

        lastCheck  = ti;
        cantChecks = cantChecks +1;
        setAccs('> [ Día: ${ti.day} | Hora: ${ pad('${ti.hour}') }:${ pad('${ti.minute}') }:${ pad('${ti.second}') } ] #$cantChecks');
        waitIsWorking = true;
        setAccs('[!] PAUSADO TEMPORAL');
        final has = await TaskFromServer.checkCambionEnCentinela(uriCheckCron);
        if(has.containsKey('err')) {

          String err = '[X] Error al CHECAR Ver. Centinela';
          if(has['err'].isNotEmpty) {
            err = '[X] ${has['err']}';
          }
          setAccs(err);
          return;
        }

        hasMisselanius = (has.containsKey('misselanius') && has['misselanius'])
          ? true : false;
        
        if(has['centinela']) {
          // Hay cambios en el centinela, procesamos los miselanius despues
          // de descargar el nuevo archivo.
          setAccs('[!] Detectada nueva versión...');
          secc = 'downCent';
        }else{
          // No hay cambios en el centinela, pero si en otros elementos
          // see, resps, noTengo, campañas etc...
          if(hasMisselanius) {
            hasMisselanius = false;
            await ChangesMisselanius.check(this);
            setAccs('[!] REANUDANDO CRON');
            waitIsWorking = false;
          }
        }
      }

    }else{
      _globals.versionCentinela = await TaskFromServer.getVersionCentinelaCurrent();
    }
  }

}