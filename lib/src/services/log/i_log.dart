import 'dart:io';
import 'dart:convert';

import 'log_entity.dart';
import '../get_paths.dart';
import '../../config/globals.dart';
import '../../config/sng_manager.dart';

class Ilog {

  final filename = 'harbi_log.json';
  final StackTrace _trace;
  final _globals = getSngOf<Globals>();

  LogEntity e = LogEntity();

  Ilog(this._trace, {required String acc, String res = ''}) {
    _parseTrace(acc, res);
  }

  ///
  void _parseTrace(String acc, String res) {

    if(!_globals.debug) { return; }
    if(acc == 'init') {
      _traceClean();
      return;
    }
    e = LogEntity();
    e.acc = acc; e.res = res;
    var traceString = _trace.toString().split("\n")[0];

    var partes = traceString.split(' ');
    List<String> fileInfo = [];
    if(partes.isNotEmpty) {

      for (var i = 0; i < partes.length; i++) {
        if(partes[i].isNotEmpty && partes[i].length > 1) {

          partes[i] = partes[i].trim();
          if(partes[i].contains('.dart')) {
            List<String> elements = [];
            if(partes[i].contains(GetPaths.getSep())) {
              elements = partes[i].split(GetPaths.getSep()).toList();
            }else{
              elements = partes[i].split('/').toList();
            }

            if(elements.last.endsWith(')')){
              elements.last = elements.last.replaceAll(')', '').trim();
              final p = elements.last.split(':');
              e.file = p.first;
              e.linea = p[1];
              e.column = p.last;
            }
          }
          fileInfo.add(partes[i].trim());
        }
      }
      e.metodo = fileInfo[1];
    }
    if(e.acc.isNotEmpty) {
      _putInFile(e.toJson());
    }
  }

  ///
  void _putInFile(Map<String, dynamic> data) {

    final path = GetPaths.getPathsFolderTo('logs');
    if(path != null) {
      final file = File('${path.path}${ GetPaths.getSep() }$filename');
      List<Map<String, dynamic>> content = [];
      if(file.existsSync()) {
        final txt = file.readAsStringSync();
        if(txt.isNotEmpty) {
          content = List<Map<String, dynamic>>.from(json.decode(file.readAsStringSync()));
        }
      }
      data['nReg'] = (content.isEmpty) ? '1' : '${content.length}';
      content.insert(0, data);
      file.writeAsStringSync(json.encode(content));
    }
  }

  ///
  void _traceClean() {

    final path = GetPaths.getPathsFolderTo('logs');
    if(path != null) {
      final file = File('${path.path}${ GetPaths.getSep() }$filename');
      if(file.existsSync()) {
        file.deleteSync();
      }
    }
  }
}