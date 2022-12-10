import 'dart:io';
import 'dart:convert';
import 'package:ftpconnect/ftpconnect.dart';

import '../../providers/terminal_provider.dart';
import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../services/get_paths.dart';
import '../../services/my_http.dart';

class HarbiFTP {

  static final globals = getSngOf<Globals>();
  static late FTPConnect ftpConnect;
  static Map<String, dynamic> oldCenti = {};

  /// 
  static Future<String> downFileFiltros(
    String pathFileDown, String toPath) async 
  {
    int result = -1;
    String res = 'ok';
    if(globals.env != 'dev') {
      result = await _downFileFtp(pathFileDown, toPath);
    }

    if(result != 4) {
      final filtros = await _downFileHttp(pathFileDown, 'download_filtros');
      if(filtros.isNotEmpty) {
        final file = File(await GetPaths.getFileByPath(toPath));
        file.writeAsStringSync(json.encode(filtros));
      }else{
        res = '$result';
      }
    }

    return res;
  }

  /// Retornamos el manifiesto del cambio reciente
  static Future<String> downFile(
    String pathFileDown, String toPath, TerminalProvider prov) async 
  {

    final file = File(await GetPaths.getFileByPath(toPath));
    if(file.existsSync()) {
      final inFile = file.readAsStringSync();
      if(inFile.isNotEmpty) {
        final content = json.decode(inFile);
        oldCenti = Map<String, dynamic>.from(content);
      }
    }

    int result = -1;
    if(globals.env == 'dev') {
      result = (oldCenti.isEmpty) ? 0 : 3;
    }

    Map<String, dynamic> centi = {};
    // if(globals.env != 'dev') {
    //   result = await _downFileFtp(pathFileDown, toPath);
    // }

    // if(result == 0) {
    //   prov.setAccs('> Recuperando Schema Centinela.');
    //   await Future.delayed(const Duration(milliseconds: 250));
    //   centi = await _buildCentinelaViaHttp(pathFileDown, toPath, prov);
    // }

    centi = await _downFileHttp(pathFileDown, 'download_centinela');
    if(centi.isEmpty) {
      prov.setAccs('> Recuperando Schema Centinela.');
      centi = await _buildCentinelaViaHttp(pathFileDown, toPath, prov);
    }else{
      prov.setAccs('[√] Descarga HTTP exitosa');
      file.writeAsStringSync(json.encode(centi));
    }
    
    // Esta es por si fallo la descarga del centinela via FTP
    if(result == 3) {
      centi = await _downFileHttp(pathFileDown, 'download_centinela');
      if(centi.isEmpty) {
        prov.setAccs('> Recuperando Schema Centinela.');
        centi = await _buildCentinelaViaHttp(pathFileDown, toPath, prov);
      }else{
        prov.setAccs('[√] Descarga HTTP exitosa');
        file.writeAsStringSync(json.encode(centi));
      }
    }

    // Si la descarga via FTP fue exitosa, volvemos a cargar el contenido desde
    // el archivo.
    if(result == 4) {
      final inFile = file.readAsStringSync();
      if(inFile.isNotEmpty) {
        final dataCenti = json.decode(inFile);
        if(dataCenti.isNotEmpty){
          centi = Map<String, dynamic>.from(dataCenti);
        }else{
          centi = {};
        }
      }
    }

    return 'ok';
  }

  /// Retornamos el manifiesto del cambio reciente
  static Future<int> _downFileFtp(String pathFileDown, String toPath) async 
  {
    bool res = false;
    String conn = 'same';

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

      int existe = 1;
      try {
        existe = ( await ftpConnect.existFile(pathFileDown) ) ? 1 : 0;
      } catch (_) {
        existe = 2;
      }

      if(existe == 2) {
        try {
          await ftpConnect.disconnect();
        } catch (_) {}
        return existe;
      }

      if(existe == 0) {
        try {
          await ftpConnect.disconnect();
        } catch (_) {}
        return existe;
      }

      if(existe == 1) {
        try {
          res = await ftpConnect.downloadFileWithRetry(pathFileDown, File(pLocalFile));
          await ftpConnect.disconnect();
        } catch (_) {}
      }

    }else{
      return 0;
    }

    if(!res) {
      return 3;
    }else{
      return 4;
    }
  }

  /// Retornamos el manifiesto del cambio reciente
  static Future<Map<String, dynamic>> _buildCentinelaViaHttp(
    String pathFileDown, String toPath, TerminalProvider prov ) async 
  {

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
    String pathFileDown, String uri) async 
  {

    bool isLoc = (globals.env == 'dev') ? true : false;
    String url = await GetPaths.getUri(uri, isLocal: isLoc);
    await MyHttp.get(url);

    if (!MyHttp.result['abort']) {
      final content = (MyHttp.result['body'].isEmpty) ? {} : MyHttp.result['body'];
      if(content.isNotEmpty) {
        return Map<String, dynamic>.from(content);
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
