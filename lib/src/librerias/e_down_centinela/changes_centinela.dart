import 'dart:io';
import 'dart:convert';

import 'package:harbi/src/config/globals.dart';

import '../run_exe.dart';
import '../../providers/terminal_provider.dart';
import '../../services/get_paths.dart';

class ChangesCentinela {

  static Map<String, dynamic> _newData = {};
  static Map<String, dynamic> _oldCenti = {};
  static List<String> toDown = [];

  ///
  static void dispose() {
    _newData = {};
    _oldCenti = {};
    toDown = [];
  }

  /// Revisamos si hay elementos que se tengan que descargar
  static Future<void> chek(
    String toPath, Map<String, dynamic> oldData, TerminalProvider prov
  ) async {

    _oldCenti = Map<String, dynamic>.from(oldData);
    oldData = {};

    final pLocalFile = await GetPaths.getFileByPath(toPath);
    final file = File(pLocalFile);
    if(file.existsSync()) {
      final content = json.decode(file.readAsStringSync());
      if(content.isNotEmpty) {
        _newData = Map<String, dynamic>.from(content);
      }
    }
    
    final has = await _hasOrdenesNew(prov);
    if(has){ _goForDowOrdSave(prov); }
  }

  /// Nuevas ordenes
  static Future<bool> _hasOrdenesNew(TerminalProvider prov) async {

    prov.setAccs('> Revisando nuevas ORDENES');
    final ordOld = (!_oldCenti.containsKey('ordenes')) ? [] : List<String>.from(_oldCenti['ordenes']);
    final ordNew = (!_newData.containsKey('ordenes')) ? [] : List<String>.from(_newData['ordenes']);

    toDown = [];
    for (var i = 0; i < ordNew.length; i++) {
      if(!ordOld.contains(ordNew[i])) {
        toDown.add(ordNew[i]);
      }
    }

    if(toDown.isNotEmpty) {
      prov.setAccs('> HAY NUEVAS ORDENES...');
      return true;
    }else{
      prov.setAccs('> Sin cambios en las ORDENES.');
      return false;
    }
  }

  ///
  static Future<void> _goForDowOrdSave(TerminalProvider prov) async {

    final globals = Globals();
    String tit = '> Iniciando proceso [DOWORDSAVE]';
    if(globals.env == 'dev'){
      toDown.insert(0, 'dev');
      tit = '> Iniciando proceso como DEV [DOWORDSAVE]';
    }
    prov.setAccs(tit);
    RunExe.start('dowordsave', args: toDown);
  }
}