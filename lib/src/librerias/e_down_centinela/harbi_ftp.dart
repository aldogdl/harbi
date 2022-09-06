import 'dart:io';
import 'dart:convert';
import 'package:ftpconnect/ftpconnect.dart';

import '../../providers/terminal_provider.dart';
import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../services/get_paths.dart';
import '../../services/my_http.dart';

class HarbiFTP {

  static Globals globals = getSngOf<Globals>();
  static late FTPConnect ftpConnect;
  static Map<String, dynamic> oldCenti = {};

  /// Retornamos el manifiesto del cambio reciente
  static Future<String> downFile(
    String pathFileDown, String toPath, TerminalProvider prov
  ) async {

    final file = File(await GetPaths.getFileByPath(toPath));
    if(file.existsSync()) {
      final inFile = file.readAsStringSync();
      if(inFile.isNotEmpty) {
        final content = json.decode(inFile);
        oldCenti = Map<String, dynamic>.from(content);
      }
    }

    final centi = await _downFileFtp(pathFileDown, toPath, prov);
    if(centi.isNotEmpty) {
      globals.versionCentinela = '${centi['version']}';
      prov.currentVersion = '${centi['version']}';
    }else{
      globals.versionCentinela = '0';
      prov.currentVersion = '0';
    }

    return 'ok';
  }

  /// Retornamos el manifiesto del cambio reciente
  static Future<Map<String, dynamic>> _downFileFtp(
    String pathFileDown, String toPath, TerminalProvider prov
  ) async {

    bool res = false;
    String conn = 'same';
    Map<String, dynamic> data = {};

    try {
      final cd = await ftpConnect.currentDirectory();
      if(cd != '/public_html') {
        conn = await _makeConn();
      }
    } catch (e) {
      conn = await _makeConn();
    }

    final pLocalFile = await GetPaths.getFileByPath(toPath);
    if (conn == 'ok' || conn == 'same') {

      if(conn == 'ok') {
        prov.setAccs('[√] Conexión FTP exitosa');
      }

      prov.setAccs('> Revisando Existencia de Centinela');
      int existe = 1;
      try {
        existe = ( await ftpConnect.existFile(pathFileDown) ) ? 1 : 0;
      } catch (_) {
        existe = 2;
      }

      if(existe == 2) {
        prov.setAccs('[X] Error de conección FTP');
        await ftpConnect.disconnect();
        return {};
      }

      if(existe == 0) {
        prov.setAccs('[X] Centinela Inexistente');
        await Future.delayed(const Duration(milliseconds: 250));
        prov.setAccs('> Recuperando Schema Centinela.');
        try {
          await ftpConnect.disconnect();
          return await _buildCentinelaViaHttp(pathFileDown, toPath, prov);
        } catch (_) {}
      }

      if(existe == 1) {
        prov.setAccs('> Descargando centinela...');
        try {
          res = await ftpConnect.downloadFileWithRetry(pathFileDown, File(pLocalFile));
          await ftpConnect.disconnect();
        } catch (_) {}
      }

    }else{
      prov.setAccs('[X] ERROR de Descarga centinela');
    }

    if(!res) {
      prov.setAccs('[X] ERROR de Descarga vía FTP');
      data = await _downFileHttp(pathFileDown, toPath, prov);
      if(data.isEmpty) {
        prov.setAccs('[X] ERROR de Descarga TOTAL');
      }else{
        prov.setAccs('[√] Descarga HTTP exitosa');
      }
    }else{

      final file = File(pLocalFile);
      prov.setAccs('[√] Descarga FTP exitosa');
      final inFile = file.readAsStringSync();
      if(inFile.isNotEmpty) {
        final dataCenti = json.decode(inFile);
        if(dataCenti.isNotEmpty){
          data = Map<String, dynamic>.from(dataCenti);
        }else{
          data = {};
        }
      }
    }

    return data;
  }

  /// Retornamos el manifiesto del cambio reciente
  static Future<Map<String, dynamic>> _buildCentinelaViaHttp(
    String pathFileDown, String toPath, TerminalProvider prov
  ) async {

    prov.setAccs('> Construyendo vía HTTP');

    String fileName = await GetPaths.getFileByPath(toPath);    
    String uri = await GetPaths.getUri('build_centinela_schema', isLocal: false);

    await MyHttp.get(uri);
    if (!MyHttp.result['abort']) {
      final content = (MyHttp.result['body'].isEmpty) ? {} : MyHttp.result['body'];
      if(content.isNotEmpty) {
        final resBody = Map<String, dynamic>.from(content);
        File(fileName).writeAsStringSync(json.encode(resBody));
        prov.setAccs('[√] Creación HTTP exitosa');
        await setVersionOnGlobals();
        return resBody;
      }else{
        prov.setAccs('[X] No se pudo Crear Centinela');
      }
    }
    return {};
  }

  /// Retornamos el manifiesto del cambio reciente
  static Future<Map<String, dynamic>> _downFileHttp(
    String pathFileDown, String toPath, TerminalProvider prov
  ) async {

    prov.setAccs('> Descargando vía HTTP');

    String fileName = await GetPaths.getFileByPath(toPath);    
    String uri = await GetPaths.getUri(
      'download_centinela', isLocal: globals.workOnlyLocal
    );
    await MyHttp.get(uri);

    if (!MyHttp.result['abort']) {
      final content = (MyHttp.result['body'].isEmpty) ? {} : MyHttp.result['body'];
      if(content.isNotEmpty) {
        final resBody = Map<String, dynamic>.from(content);
        File(fileName).writeAsStringSync(json.encode(resBody));
        await setVersionOnGlobals();
        return resBody;
      }
    }
    return {};
  }

  ///
  static Future<void> setVersionOnGlobals() async {

    final uriPath = await GetPaths.getFileByPath('centinela');
    File centi = File(uriPath);
    if (centi.existsSync()) {
      Map<String, dynamic>? content = json.decode(centi.readAsStringSync());
      if (content != null) {
        if(content.containsKey('version')) {
          globals.versionCentinela = '${content['version']}';
        }
      }
      content = null;
    }
  }

  ///
  static Future<String> _makeConn() async {

    final data = await GetPaths.getConnectionFtp(isLocal: false);
    if (data['url'].startsWith('http')) {
      final partes = data['url'].split('//');
      data['url'] = partes.last;
      if (data['url'].endsWith('/')) {
        data['url'] = data['url'].replaceAll('/', '').trim();
      }
    }
    ftpConnect = FTPConnect(
      data['url'],
      user: data['u'],
      pass: data['p'],
      isSecured: data['ssl']
    );

    try {
      await ftpConnect.connect();
    } catch (e) {
      return e.toString();
    }

    if(data['ssl']) {
      await ftpConnect.changeDirectory(GetPaths.package);
    }
    await ftpConnect.changeDirectory('public_html');
    return 'ok';
  }
  
  // ///
  // static Future<bool> upFile(String pathFileForUp, List<String> inPaths) async {

  //   log.task = 'Cargando Archivo $pathFileForUp';

  //   final conn = await _makeConn();
  //   if (conn != 'ok') {
  //     return false;
  //   }

  //   try {
  //     File fileToUpload = File(pathFileForUp);
  //     for (var i = 0; i < inPaths.length; i++) {
  //       await ftpConnect.changeDirectory(inPaths[i]);
  //     }
  //     bool res = await ftpConnect.uploadFile(fileToUpload);
  //     await ftpConnect.disconnect();
  //     return res;
  //   } catch (e) {
  //     return false;
  //   }
  // }

}
