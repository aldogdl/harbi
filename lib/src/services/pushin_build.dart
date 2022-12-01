import 'dart:convert';
import 'dart:io';

import 'get_paths.dart';

class PushInBuild {

  // Push recien llgedos con exito "scp_pushin"
  // Push ya procesados por el scp "scp_pushout"
  // Push recien llgedos con con error de recuperacion "scp_pushlost"
  static Map<String, dynamic> foldersPush = {
    'in' : 'pushin', 'out': 'pushout', 'lost' : 'pushlost'
  };

  ///
  static void setIn(String prefix, Map<String, dynamic> schema) {

    final sep = GetPaths.getSep();
    final dir = GetPaths.getPathsFolderTo(foldersPush['in']);

    if(dir != null) {
      String nameFile = '$prefix-${DateTime.now().millisecondsSinceEpoch}.json';
      File('${dir.path}$sep$nameFile').writeAsStringSync(json.encode(schema));
    }
  }

  ///
  static Map<String, dynamic> getSchemaMain({
    required String priority,
    required String secc,
    required String titulo,
    required String descrip,
    required Map<String, dynamic> data,
    String idAvo = '0',
  }) {

    return {
      'idAvo'   : idAvo,
      'secc'    : secc,
      'priority': priority,
      'titulo'  : titulo,
      'descrip' : descrip,
      'sended'  : DateTime.now().toIso8601String(),
      'data'    : data,
    };
  }
}