import 'dart:io';
import 'dart:convert';

import 'ejecuta.dart';
import '../services/get_paths.dart';
import '../providers/terminal_provider.dart';

class ChangesMisselanius {

  static const nameFile = 'misselanius_';

  static List<Map<String, dynamic>> _changes = [];
  static List<int> _campas = [];
  static List<int> _filtros = [];

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
    
    if(_changes.isNotEmpty) {
      for (var i = 0; i < _changes.length; i++) {
        if(_changes[i].containsKey('scm')) {
          _campas.addAll(List<int>.from(_changes[i]['scm']));
        }
        if(_changes[i].containsKey('filtros')) {
          _filtros.addAll(List<int>.from(_changes[i]['filtros']));
        }
        if(_changes[i].containsKey('scmSee')) {
          goForScmSee = _changes[i]['scmSee'];
        }
        if(_changes[i].containsKey('scmResp')) {
          goForScmResp = _changes[i]['scmResp'];
        }
      } 
    }

    if(_campas.isNotEmpty) { await _hasCampaniasNew(prov); }
    if(_filtros.isNotEmpty) { await _hasFiltrosNew(prov);  }
    if(goForScmSee) { await _goForScmSee(prov); }
    if(goForScmResp) { await _goForScmResp(prov); }

    _changes = [];
  }

  /// Revisamos si hay nuevas descargas y vistas de cotizadores
  static Future<void> _goForScmSee(TerminalProvider prov) async {

    prov.setAccs('> Iniciando proceso [REGSCMSEE]');
    Ejecuta.exe('regScmSee', args: []);
    prov.setAccs('[^] Se requiere de NOTIFICACIÓN');
    prov.requiredNotiff = true;
  }

  /// Revisamos si hay nuevas respuestas de cotizadores a solicitudes
  static Future<void> _goForScmResp(TerminalProvider prov) async {

    prov.setAccs('> Iniciando proceso [REGSCMRESP]');
    Ejecuta.exe('regScmResp', args: []);
    prov.setAccs('[^] Se requiere de NOTIFICACIÓN');
    prov.requiredNotiff = true;
  }

  /// Revisamos si hay nuevas campañas
  static Future<void> _hasCampaniasNew(TerminalProvider prov) async {

    if(_campas.isNotEmpty) {
      prov.setAccs('> Iniciando proceso [NEWCAMPAS]');
      final args = _campas.map((e) => '$e').toList();

      Ejecuta.exe('newcampas', args: args);
      prov.setAccs('[^] Se requiere de NOTIFICACIÓN');
      prov.requiredNotiff = true;
      _campas = [];
    }else{
      prov.setAccs('[!] Sin nuevas CAMPAÑAS');
    }
  }

  ///
  static Future<void> _hasFiltrosNew(TerminalProvider prov) async {
    
    if(_filtros.isNotEmpty) {
      prov.setAccs('> Iniciando proceso [NEWFILTROS]');
      final args = _filtros.map((e) => '$e').toList();

      Ejecuta.exe('newfiltros', args: args);
      prov.setAccs('[^] Se requiere de NOTIFICACIÓN');
      prov.requiredNotiff = true;
      _filtros = [];
    }else{
      prov.setAccs('[!] Sin nuevos FILTROS');
    }
  }

}