import 'dart:io';
import 'dart:convert';

import '../run_exe.dart';
import '../../services/get_paths.dart';
import '../../providers/terminal_provider.dart';

class ChangesMisselanius {

  static const nameFile = 'misselanius_';

  static List<Map<String, dynamic>> _changes = [];
  static bool _campas = false;

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

    prov.setAccs('> Revisando MISSELANIUS:');
    bool hasChanges = false;
    await Future.delayed(const Duration(milliseconds: 250));

    final pathToLog = GetPaths.getPathsFolderTo('logs');
    if(pathToLog != null) {

      final lst = pathToLog.listSync();
      for (var i = 0; i < lst.length; i++) {

        Uri uri = Uri.file(lst[i].path, windows: true);
        final segs = uri.pathSegments;
        if(segs.last.startsWith(nameFile)) {
          final file = File(lst[i].path);
          _changes.add(Map<String, dynamic>.from(json.decode(file.readAsStringSync())));
          file.deleteSync();
        }
      }
    }

    bool goForScmSee = false;
    bool goForScmResp = false;
    bool goForFiltros = false;
    
    if(_changes.isNotEmpty) {

      for (var i = 0; i < _changes.length; i++) {
        
        if(_changes[i].containsKey('camping')) {
          _campas = _changes[i]['camping'];
        }
        if(_changes[i].containsKey('filNtg')) {
          prov.setAccs('> [ ${_changes[i]['filNtg'] } ] FILTROS NT Detectados');
          goForFiltros = (_changes[i]['filNtg'] > 9) ? true : false;
        }
        if(_changes[i].containsKey('filCnm')) {
          goForFiltros = _changes[i]['filCnm'];
        }
        if(_changes[i].containsKey('scmSee')) {
          goForScmSee = _changes[i]['scmSee'];
        }
        if(_changes[i].containsKey('scmResp')) {
          goForScmResp = _changes[i]['scmResp'];
        }
      } 
    }

    if(goForFiltros) {
      hasChanges = true;
      prov.setAccs('> HAY NUEVOS FILTROS...');
      await Future.delayed(const Duration(milliseconds: 250));
      await _goForFiltros(prov); 
    }

    if(_campas) {
      hasChanges = true;
      prov.setAccs('> HAY NUEVAS CAMPAÑAS...');
      await Future.delayed(const Duration(milliseconds: 250));
      await _hasCampaniasNew(prov);
    }
    
    if(goForScmSee) {
      hasChanges = true;
      prov.setAccs('> HAY VISTAS DE CAMPAÑAS...');
      await Future.delayed(const Duration(milliseconds: 250));
      await _goForScmSee(prov);
    }

    if(goForScmResp) {
      hasChanges = true;
      prov.setAccs('> HAY NUEVAS RESPUESTAS...');
      await Future.delayed(const Duration(milliseconds: 250));
      await _goForScmResp(prov);
    }

    _changes = [];
    if(!hasChanges) {
      prov.setAccs('> Sin cambios en MISSELANIUS.');
    }
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  /// Revisamos si hay nuevas descargas y vistas de cotizadores
  static Future<void> _goForScmSee(TerminalProvider prov) async {

    prov.setAccs('> Iniciando proceso [REGSCMSEE]');
    RunExe.start('regScmSee', args: []);
  }

  /// Revisamos si hay nuevas respuestas de cotizadores a solicitudes
  static Future<void> _goForScmResp(TerminalProvider prov) async {

    prov.setAccs('> Iniciando proceso [REGSCMRESP]');
    RunExe.start('regScmResp', args: []);
  }

  /// Revisamos si hay nuevas campañas
  static Future<void> _hasCampaniasNew(TerminalProvider prov) async {

    if(_campas) {
      prov.setAccs('> Iniciando proceso [NEWCAMPAS]');
      RunExe.start('newcampas', args: []);
      _campas = false;
    }else{
      prov.setAccs('[!] Sin nuevas CAMPAÑAS');
    }
  }

  ///
  static Future<void> _goForFiltros(TerminalProvider prov) async {

    prov.setAccs('> Iniciando proceso [NEWFILTROS]');
    RunExe.start('newfiltros', args: []);
  }

}