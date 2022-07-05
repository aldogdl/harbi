import 'dart:io';
import 'dart:convert';

import '../services/get_paths.dart';

class MakeRutas {

  /// Construimos las rutas (Estaciones y status) generales
  static Future<bool> crear() async {

    List<String> sep = [GetPaths.getSep()];

    //<---- RUTAS (Si las rutas estan bacias) ---->
    String pathRutas = await GetPaths.getFileByPath('rutas');
    File rutasF = File(pathRutas);
    String hasRutas = '';
    if(rutasF.existsSync()) {
      hasRutas = rutasF.readAsStringSync();
    }

    String filename = '';
    late String content;

    if(hasRutas.isEmpty) {
      String pathR = GetPaths.getPathRoot();
      Directory? patRoot = Directory(pathR);
      filename = 'estaciones.txt';
      content = await GetPaths.getContentAssetsBy(filename);
      File('${patRoot.path}${sep.first}$filename').writeAsStringSync(content);
      
      filename = 'estatus.txt';
      content = await GetPaths.getContentAssetsBy(filename);
      File('${patRoot.path}${sep.first}$filename').writeAsStringSync(content);
      await _buildRutas();
      return true;
    }
    return false;
  }

  ///
  static Future<bool> _buildRutas() async {

    bool go = false;
    Map<String, dynamic> ruta = {};
    List<String> sep = [GetPaths.getSep()];

    String pathR = GetPaths.getPathRoot();
    Directory? patRoot = Directory(pathR);
    File stt = File('${patRoot.path}${sep.first}estaciones.txt');
    if (stt.existsSync()) {

      ruta['est'] = _buildEstaciones(stt.path);
      ruta['ext'] = _buildExtras(stt.path);

      stt = File('${patRoot.path}${sep.first}estatus.txt');
      if (stt.existsSync()) {
        ruta['stt'] = _buildEstatus(stt.path);
        go = true;
      }
    }

    if (go) {
      await _buildRutaPieza(ruta);
      return true;
    }

    return false;
  }

  ///
  static Map<String, dynamic> _buildEstaciones(String path) {

    Map<String, dynamic> estaciones = {};
    File estFile = File(path);
    int linea = 1;

    estFile.readAsLinesSync().map((String line) {

      if(!line.startsWith('extras')) {
        List<String> partes = line.split(',');
        estaciones[partes.first.trim()] = {
          'id': '$linea',
          'nom': partes.last.trim()
        };
        linea++;
      }
    }).toList();

    return estaciones;
  }

  ///
  static Map<String, dynamic> _buildExtras(String path) {

    Map<String, dynamic> extras = {};
    File estFile = File(path);
    
    estFile.readAsLinesSync().map((String line) {
      if(line.startsWith('extras')) {
        List<String> partes = line.split(',');
        extras[partes[1].trim()] = partes.last.trim();
      }
    }).toList();

    estFile.deleteSync();
    return extras;
  }

  ///
  static List<Map<String, dynamic>> _buildEstatus(String path) {

    List<Map<String, dynamic>> estatus = [];
    File estFile = File(path);
    int linea = 1;
    String estacion = '';
    estFile.readAsLinesSync().map((String line) {
      List<String> partes = line.split(',');
      String nom = partes.last.trim();
      if (nom.isNotEmpty) {
        if (linea == 1) {
          estacion = partes.first.trim();
        }
        if (estacion != partes.first.trim()) {
          linea = 1;
          estacion = partes.first.trim();
        }
        estatus.add(
          {'est': estacion, 'id': '$linea', 'nom': partes.last.trim()}
        );
        linea++;
      }
    }).toList();

    estFile.deleteSync();
    return estatus;
  }

  ///
  static Future<void> _buildRutaPieza(Map<String, dynamic> ruta) async {

    Map<String, dynamic> laRuta = {'est': {}, 'stt': {}};

    // Estaciones
    Map<String, dynamic> rutaN = {};
    ruta['est'].forEach((key, value) {
      laRuta['est'][value['id']] = value['nom'];
      rutaN.putIfAbsent(value['id'], () => <String>[]);
    });

    // Estatus
    String estacion = ruta['stt'].first['est'];
    String idEst = ruta['est'][estacion]['id'];

    for (var i = 0; i < ruta['stt'].length; i++) {
      if (estacion != ruta['stt'][i]['est']) {
        rutaN[idEst].add('f');
        estacion = ruta['stt'][i]['est'];
        idEst = ruta['est'][estacion]['id'];
      }

      if (laRuta['stt'].containsKey(idEst)) {
        laRuta['stt'][idEst]
            .putIfAbsent(ruta['stt'][i]['id'], () => ruta['stt'][i]['nom']);
      } else {
        laRuta['stt'].putIfAbsent(
            idEst, () => {ruta['stt'][i]['id']: ruta['stt'][i]['nom']});
      }

      if (!rutaN[idEst].contains('${ruta['stt'][i]['id']}')) {
        rutaN[idEst].add('${ruta['stt'][i]['id']}');
      }
    }
    if (rutaN[idEst].last != 'f') {
      rutaN[idEst].add('f');
    }

    String pathRta = await GetPaths.getFileByPath('rutas');
    File? rtaOld = File(pathRta);
    laRuta['ext'] = ruta['ext'];
    rtaOld.writeAsStringSync(jsonEncode(laRuta));

    /// Borramos los archivos temporales de las rutas
    List<String> sep = [GetPaths.getSep()];
    String pathR = GetPaths.getPathRoot();
    Directory? patRoot = Directory(pathR);
    File stt = File('${patRoot.path}${sep.first}estaciones.txt');
    if(stt.existsSync()) {
      stt.deleteSync();
    }
    stt = File('${patRoot.path}${sep.first}estatus.txt');
    if(stt.existsSync()) {
      stt.deleteSync();
    }
  }

}
