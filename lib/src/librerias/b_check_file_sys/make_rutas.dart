import 'dart:io';
import 'dart:convert';

import '../../services/get_paths.dart';

class MakeRutas {

  static Map<String, dynamic> ruta = {};

  /// Construimos las rutas (Estaciones y status) generales
  static Future<bool> crear() async {

    bool saveToServer = true;
    List<String> sep = [GetPaths.getSep()];

    //<---- RUTAS (Si las rutas estan bacias) ---->
    Map<String, dynamic> hasRutas = {};
    String pathRutas = await GetPaths.getFileByPath('rutas');
    File rutasF = File(pathRutas);
    if(rutasF.existsSync()) {
      final co = rutasF.readAsStringSync();
      if(co.isNotEmpty) {
        hasRutas = json.decode(co);
      }
    }

    String filename = 'estaciones.txt';
    final dir = GetPaths.getDirectoryAssets();
    File estF = File('${dir.path}${sep.first}$filename');

    if(estF.existsSync()) {

      estF.readAsLinesSync().map((String line) {

        List<String> partes = line.split(',');
        if(partes.first == 'ver') {
          ruta['ver'] = partes.last;
        }else{
          if(!ruta.containsKey('est')) {
            ruta.putIfAbsent('est', () => {});
          }
          if(ruta['est'].containsKey(partes.first)) {
            ruta['est'].putIfAbsent(partes.first, () => partes.last.trim());
          }else{
            ruta['est'][partes.first] = partes.last.trim();
          }
        }
      }).toList();

      if(ruta.containsKey('ver')) {
        if(hasRutas.isNotEmpty) {
          if(ruta['ver'] == hasRutas['ver']) {
            saveToServer = false;
          }
        }
      }
    }

    if(saveToServer) {
      filename = 'estatus.txt';
      await _buildEstatus('${dir.path}${sep.first}$filename');
      rutasF.writeAsStringSync(json.encode(ruta));
    }

    return saveToServer;
  }

  ///
  static Future<void> _buildEstatus(String path) async {

    File sttFile = File(path);
    int keyStt = 1;
    ruta['stt'] = <String, Map<String, String>>{};
    
    sttFile.readAsLinesSync().map((String line) {

      List<String> partes = line.split(',');
      String nom = partes.last.trim();
      if (nom.isNotEmpty) {
        var est = partes.first.trim();

        if(ruta['stt'].containsKey(est)) {
          ruta['stt'][est].putIfAbsent('$keyStt', () => partes.last.trim());
        }else{
          keyStt = 1;
          ruta['stt'].putIfAbsent(est, () => {'$keyStt':partes.last.trim()});
        }
        keyStt++;
      }
    }).toList();

  }

}
