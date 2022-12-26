import 'dart:io';
import 'dart:convert';

import '../../repository/fire_push_repository.dart';
import '../run_exe.dart';
import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../services/get_paths.dart';
import '../../providers/terminal_provider.dart';

class ChangesMisselanius {

  static const nameFile = 'misselanius_';

  static List<Map<String, dynamic>> _changes = [];
  static List<Map<String, dynamic>> _firesPush = [];
  static bool _campas = false;
  static Globals globals = getSngOf<Globals>();

  ///
  static Future<void> save(Map<String, dynamic> data) async {

    final fileName = '$nameFile${DateTime.now().millisecondsSinceEpoch}.json';
    final sep = GetPaths.getSep();
    final pathToLog = GetPaths.getPathsFolderTo('logs');
    if(pathToLog != null) {
      final file = File('${pathToLog.path}$sep$fileName');
      file.writeAsStringSync(json.encode(data));
    }
  }

  ///
  static Future<void> check(TerminalProvider prov) async {

    _firesPush = [];
    bool hasChanges = false;
    final pathToLog = GetPaths.getPathsFolderTo('logs');

    prov.setAccs('> Revisando MISSELANIUS:');
    await Future.delayed(const Duration(milliseconds: 250));

    if(pathToLog != null) {

      final lst = pathToLog.listSync().toList();
      for (var i = 0; i < lst.length; i++) {

        if(lst[i].path.contains(nameFile)) {
          final file = File(lst[i].path);
          _changes.add(Map<String, dynamic>.from(json.decode(file.readAsStringSync())));
          file.deleteSync();
        }

        // Estos archivos indican que hay que enviar notificaciones push via FireBase
        // Generalmente usados para avisar a los cotizadores que hay nuevas solicitudes
        if(lst[i].path.contains('fire_push')) {
          final file = File(lst[i].path);
          final content = _checkDuplex(file);
          if(content.isNotEmpty) {
            _firesPush.add(content);
          }
          file.deleteSync();
        }
      }
    }

    bool goForIris = false;
    bool goForScmResp = false;
    
    if(_changes.isNotEmpty) {

      for (var i = 0; i < _changes.length; i++) {

        if(_changes[i].containsKey('camping')) {
          _campas = _changes[i]['camping'];
        }

        if(_changes[i].containsKey('ntg')) {
          goForIris = _changes[i]['ntg'];
        }

        if(!goForIris) {
          if(_changes[i].containsKey('iris')) {
            goForIris = _changes[i]['iris'];
          }
        }

        if(_changes[i].containsKey('resp')) {
          goForScmResp = _changes[i]['resp'];
        }
      } 
    }

    if(_campas) {
      hasChanges = true;
      prov.setAccs('> HAY NUEVAS CAMPAÑAS...');
      await Future.delayed(const Duration(milliseconds: 250));
      await _hasCampaniasNew(prov);
    }

    if(goForIris) {
      hasChanges = true;
      prov.setAccs('> REGISTROS DE ATENCIÓN...');
      await _goForIris(prov);
    }

    if(goForScmResp) {
      hasChanges = true;
      prov.setAccs('> HAY NUEVAS RESPUESTAS...');
      await Future.delayed(const Duration(milliseconds: 250));
      await _goForScmResp(prov);
    }

    if(_firesPush.isNotEmpty) {
      hasChanges = true;
      prov.setAccs('> ENVIANDO NOTIFICACIONES...');
      await Future.delayed(const Duration(milliseconds: 250));
      await _processFirePush(prov);
    }

    _changes = [];
    if(!hasChanges) {
      prov.setAccs('> Sin cambios en MISSELANIUS.');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Revisamos que entre los archivos fire_push no existan campañas duplicadas
  static Map<String, dynamic> _checkDuplex(File fire) {

    final content = Map<String, dynamic>.from(json.decode(fire.readAsStringSync()));
    final hasDuplex = _firesPush.where((p) => p['idCamp'] == content['idCamp']);
    if(hasDuplex.isNotEmpty) {
      if(hasDuplex.first['idAvo'] == content['idAvo']) {
        if(hasDuplex.first['id'] == content['id']) {
          return {};
        }
      }
    }
    return content;
  }

  /// Revisamos si hay nuevas descargas y vistas de cotizadores
  static Future<void> _goForIris(TerminalProvider prov) async {

    // Revisamos si ya esta abierto iris total.
    final fld = GetPaths.getPathsFolderTo('logs');
    if(fld == null) return;

    final f = File('${fld.path}${ GetPaths.getSep() }open_iris.log');
    if(!f.existsSync()) {
      prov.setAccs('> Iniciando proceso [IRISTOTAL]');
      List<String> argumentos = [];
      if(globals.env == 'dev') {
        argumentos = [globals.env];
      }
      // Creamos el archivo para evitar abrir la VP nuevamente
      f.writeAsStringSync('');
      RunExe.start('iristotal', args: argumentos);
    }else{
      prov.setAccs('> Notificando a [IRISTOTAL]');
      final filename = 'atencion-${DateTime.now().millisecondsSinceEpoch}.log';
      File('${fld.path}${ GetPaths.getSep() }$filename').writeAsStringSync(
        'Estos archivos, son creados desde HARBI, y son para indicar que hay '
        'más archivos de atencion en el servidor remoto para descargar.'
        'Esto se hizo con la finalidad de no abrir tantos VP de IRISTOTAL.'
      );
    }
  }

  /// Revisamos si hay nuevas respuestas de cotizadores a solicitudes
  static Future<void> _goForScmResp(TerminalProvider prov) async {

    prov.setAccs('> Iniciando proceso [REGSCMRESP]');
    List<String> argumentos = [];
    if(globals.env == 'dev') {
      argumentos = [globals.env];
    }
    RunExe.start('regScmResp', args: argumentos);
  }

  /// Revisamos si hay nuevas campañas
  static Future<void> _hasCampaniasNew(TerminalProvider prov) async {

    if(_campas) {

      // Revisamos si ya esta abierto vp camp.
      final fld = GetPaths.getPathsFolderTo('logs');
      if(fld == null) return;

      final f = File('${fld.path}${ GetPaths.getSep() }open_camp.log');
      if(!f.existsSync()) {
        prov.setAccs('> Iniciando proceso [NEWCAMPAS]');
        List<String> argumentos = [];
        if(globals.env == 'dev') {
          argumentos = [globals.env];
        }
        // Creamos el archivo para evitar abrir la VP nuevamente
        f.writeAsStringSync('');
        RunExe.start('newcampas', args: argumentos);
      }else{
        prov.setAccs('> Notificando a [NEWCAMPAS]');
        final filename = 'newcamp-${DateTime.now().millisecondsSinceEpoch}.log';
        File('${fld.path}${ GetPaths.getSep() }$filename').writeAsStringSync(
          'Estos archivos, son creados desde HARBI, y son para indicar que hay '
          'más archivos de nuevas campañas en el servidor remoto para descargar.'
          'Esto se hizo con la finalidad de no abrir tantos VP de NEWCAMPAS.'
        );
      }
      _campas = false;
    }else{
      prov.setAccs('[!] Sin nuevas CAMPAÑAS');
    }
  }

  /// Procesamo los archivos de fire push, los cuales son archivos que 
  /// los crea el SCM, indicando la finalizacion del envio de una campaña
  static Future<void> _processFirePush(TerminalProvider prov) async {

    final fpEm = FirePushRepository();
    prov.setAccs('[√] ---------- [ SCM ] ----------.');
    prov.setAccs('> Liberando ORDENES para cotizadores');
    await Future.delayed(const Duration(milliseconds: 150));
    prov.setAccs('> Guardando Registros en Iris File');
    prov.setAccs('> Guardando Registros en Métricas');
    await Future.delayed(const Duration(milliseconds: 150));
    prov.setAccs('> PROCESANDO FINALIZACIÓN DE CAMPAÑA');
    prov.setAccs('[√] ---------- [ SCM ] ----------.');
    await Future.delayed(const Duration(milliseconds: 150));

    bool isLocal = (globals.env == 'dev') ? true : false;
    List<String> liberar = [];
    bool hasErr = false;

    for (var i = 0; i < _firesPush.length; i++) {
      
      final idOrd = _firesPush[i]['data']['id'].toString().trim();
      if(!liberar.contains(idOrd)) {
        liberar.add(idOrd);
      }

      prov.setAccs('[!] ANALIZANDO ORDEN $idOrd.');
      String expOrd = fpEm.getFolderExp(_firesPush[i]['data']['id']);
      if(expOrd.isNotEmpty) {

        // Tomamos las metricas del archivo de envio.
        final metrixF = File('$expOrd${_firesPush[i]['data']['idCamp']}${fpEm.s}metrix.json');
        final irisF = File('$expOrd$idOrd${"_iris.json"}');

        if(metrixF.existsSync()) {
          final metrix = Map<String, dynamic>.from(json.decode(metrixF.readAsStringSync()));
          var idsCots = List<int>.from(metrix['sended']);
          prov.setAccs('[>] REVISANDO ${idsCots.length} COTIZADORES.');

          if(irisF.existsSync()) {
            final iris = Map<String, dynamic>.from(json.decode(irisF.readAsStringSync()));
            if(iris.isNotEmpty) {
              // Analizamos para ver si algun cotizador ya atendio
              iris.forEach((key, value) {
                if(key != 'avo' && key != 'version') {
                  final regs = Map<String, dynamic>.from(value);
                  for (var c = 0; c < idsCots.length; c++) {
                    if(regs.containsKey('${idsCots[c]}')) {
                      idsCots.removeAt(c);
                    }
                  }
                }
              });
            }
          }

          prov.setAccs('[>] CHECANDO FRECUENCIA DE ${idsCots.length} COTIZADORES.');
          idsCots = await fpEm.checkFrecuencia(idsCots);

          prov.setAccs('[>] ENVIANDO A ${idsCots.length} COTIZADORES.');
          final res = await fpEm.sendPushTo(
            _firesPush[i]['data']['id'], '${_firesPush[i]['data']['idCamp']}',
            '${_firesPush[i]['data']['idAvo']}', idsCots, isLocal: isLocal
          );

          if(res.containsKey('abort')) {
            if(res['abort']) {
              prov.setAccs('[X] ERROR AL ENVIAR PUSH ORDEN $idOrd.');
              hasErr = true;
            }
          }

          if(!hasErr) {
            if(idsCots.isNotEmpty) {
              prov.setAccs('[>] ACTUALIZANDO FRECUENCIA A COTIZADORES.');
              await fpEm.updateFrecuencia(idsCots, res);
              prov.setAccs('[√] ORDEN $idOrd. ENVIADA');
            }
          }
        }else{
          prov.setAccs('[X] NO EXISTEN METRICAS ORDEN $idOrd.');
          hasErr = true;
        }
      }else{
        prov.setAccs('[X] EXPEDIENTE INEXISTENTE ORDEN $idOrd.');
        hasErr = true;
      }
    }

    if(hasErr) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if(liberar.isNotEmpty) {
      prov.setAccs('[>] LIBERANDO ORDENES.');
      await fpEm.liberarOrden(liberar.join(','));
      prov.setAccs('[√] ORDENES PUBLICADAS CON ÉXITO');
    }
  }

}