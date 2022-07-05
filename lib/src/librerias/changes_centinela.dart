import 'dart:io';
import 'dart:convert';

import '../librerias/ejecuta.dart';
import '../providers/terminal_provider.dart';
import '../services/get_paths.dart';

class ChangesCentinela {

  static Map<String, dynamic> _newData = {};
  static Map<String, dynamic> _oldCenti = {};

  /// Revisamos si hay elementos que se tengan que descargar
  static Future<void> chek(
    String toPath,
    Map<String, dynamic> oldData,
    TerminalProvider prov
  ) async {

    _oldCenti = Map<String, dynamic>.from(oldData);
    oldData = {};

    final pLocalFile = await GetPaths.getFileByPath(toPath);
    final file = File(pLocalFile);
    if(file.existsSync()) {
      final content = file.readAsStringSync();
      if(content.isNotEmpty) {
        _newData = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
      }
    }

    // Elementos descargables:
    await _hasOrdenesNew(prov);
    
    prov.setAccs('[!] Sin Respuestas a cotizaciones');
    // Nevas respuestas a 
    // TODO
    
  }

  /// Nuevas ordenes
  static Future<void> _hasOrdenesNew(TerminalProvider prov) async {

    prov.setAccs('> Revisando nuevas ordenes');
    final ordOld = (!_oldCenti.containsKey('ordenes')) ? [] : List<String>.from(_oldCenti['ordenes']);
    final ordNew = (!_newData.containsKey('ordenes')) ? [] : List<String>.from(_newData['ordenes']);
    var toDown = <String>[];
    for (var i = 0; i < ordNew.length; i++) {
      if(!ordOld.contains(ordNew[i])) {
        toDown.add(ordNew[i]);
      }
    }

    if(toDown.isNotEmpty) {
      prov.setAccs('> Iniciando proceso [DOWORDSAVE]');
      Ejecuta.exe('dowordsave', args: toDown);
      prov.setAccs('[^] Se requiere de NOTIFICACIÓN');
      prov.requiredNotiff = true;
    }else{
      prov.setAccs('[!] Sin nuevas ORDENES');
    }
  }

}