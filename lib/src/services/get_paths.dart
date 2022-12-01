import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart' show Size;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../config/globals.dart';
import '../config/sng_manager.dart';

class GetPaths {

  static final Globals globals = getSngOf<Globals>();

  static String env = 'dev';

  static const String package = 'autoparnet';
  static const String userShare = '_userPc_';
  static const String nameFilePaths = 'paths_dev.json';
  static const String nameFilePathsP = 'paths_prod.json';
  static const String nameFilePathsPS = 'paths_prod_shared.json';
  static p.Style estiloPlatform = p.Style.windows;

  /// Obtenemos el separador del sistema
  static String getSep() {
    var context = p.Context(style: estiloPlatform);
    return context.separator;
  }

  ///
  static Directory getDirectoryAssets({String subFold = ''}) {
    
    List<String> sep = [getSep()];
    String folder = 'assets';
    String path = '';

    String pathExe = Platform.resolvedExecutable;
    if(pathExe.contains('Debug')){
      if(p.context.current.endsWith('bin')) {
        path = '${p.context.current}${sep.first}..${sep.first}$folder';
      }else{
        path = '${p.context.current}${sep.first}$folder';
      }
      if(subFold.isNotEmpty) {
        subFold = '$subFold${sep.first}';
      } 
      return Directory('${p.context.normalize(path)}${sep.first}$subFold');
    }else{
      
      Uri uri = Uri.file(pathExe);
      final partes = List<String>.from(uri.pathSegments);
      partes.removeLast();
      pathExe = partes.join(sep.first);
      pathExe = p.join(pathExe, 'data', 'flutter_assets', folder, subFold);
      return Directory(pathExe);
    }
  }

  ///
  static Future<String> getContentAssetsBy(String filename) async {
    
    final dir = getDirectoryAssets();
    final file = File('${dir.path}${getSep()}$filename');
    if(file.existsSync()) {
      return file.readAsStringSync();
    }
    return await rootBundle.loadString('assets${getSep()}$filename', cache: false);
  }

  /// Recuperamos la data del archivo de paths que se comparte entre sistemas
  static Future<Map<String, dynamic>> getContentFilePathShared() async {

    List<String> sep = [getSep()];
    final paths = File('${getPathRoot()}${sep.first}$nameFilePathsPS');
    if (paths.existsSync()) {
      return {'body':json.decode(paths.readAsStringSync())};
    }
    return {};
  }

  /// Recuperamos la data del archivo principal de paths
  static Future<Map<String, dynamic>?> getContentFilePaths({bool isProd = false}) async {

    List<String> sep = [getSep()];
    Map<String, dynamic>? pathsFinder;
    late File paths;
    if (!isProd) {
      final assets = await getContentAssetsBy(nameFilePaths);
      pathsFinder = Map<String, dynamic>.from(json.decode(assets));
    } else {
      paths = File('${getPathRoot()}${sep.first}$nameFilePathsP');
      if (paths.existsSync()) {
        pathsFinder = Map<String, dynamic>.from(
          json.decode(paths.readAsStringSync())
        );
      }
    }
    
    return pathsFinder;
  }

  /// Obtenemos el path a root del proyecto
  static String getPathRootShare() {
    var context = p.Context(style: estiloPlatform);
    return context.join(userShare, 'com.$package');
  }

  /// Obtenemos el path a root del proyecto
  static String getPathRoot() {
    var context = p.Context(style: estiloPlatform);
    String path = context.join(Platform.environment['APPDATA']!, 'com.$package');
    Directory? dir = Directory(path);
    if(!dir.existsSync()) {
      dir.createSync();
    }
    return path;
  }

  /// Guardamos u obtenemos el tamaño de la pantalla del dispositivo
  static Future<Size> screen({String set = ''}) async {

    String root = getPathRoot();

    final file = File('$root${getSep()}screen.txt');
    if(file.existsSync()) {
      String setOld = file.readAsStringSync();
      if(setOld.isNotEmpty) {
        if(set.isNotEmpty) {
          final partes = set.split(' ');
          final parteso = setOld.split(' ');
          double w = double.parse(partes.first.trim());
          double wo = double.parse(parteso.first.trim());
          if(w > wo) {
            setOld = '$w ${partes.last}';
            file.writeAsStringSync(setOld);
          }
        }
        set = setOld;
      }else{
        if(set.isNotEmpty) {
          file.writeAsStringSync(set);
        }
      }
    }else{
      if(set.isEmpty) { set = '1281 721'; }
      file.writeAsStringSync(set);
    }
    
    final t = List<String>.from(set.split(' '));
    return Size(double.parse(t.first), double.parse(t.last));
  }

  /// Recuperamos el Archivo Screen
  static Future<File> getFileScreen() async {

    String root = getPathRoot();
    final file = File('$root${getSep()}screen.txt');
    if(!file.existsSync()) {
      file.writeAsStringSync('Sin Data');
    }
    return file;
  }

  ///
  static Future<void> deleteFilePathsProd() async {
    File paths = File('${getPathRoot()}${getSep()}$nameFilePathsP');
    if (paths.existsSync()) {
      paths.deleteSync();
    }
  }

  /// Revisamos la existencia del archivo paths para produccion
  static Future<bool> existFilePathsProd() async {
    File paths = File('${getPathRoot()}${getSep()}$nameFilePathsP');
    return paths.existsSync();
  }

  /// Recuperamos la URI segun key desde el archivo de produccion
  static Future<Map<String, dynamic>> _getFromFilePathsProd(String key) async {
    File paths = File('${getPathRoot()}${getSep()}$nameFilePathsP');
    if (paths.existsSync()) {
      Map mapa = json.decode(paths.readAsStringSync());
      if (mapa.containsKey(key)) {
        return {
          'base_r': mapa['server_remote'],
          'base_l': mapa['server_local'],
          'uri': mapa[key],
        };
      }
    }
    return {};
  }

  /// Guardamos la ip que apunta a la base de datos local
  static Future<void> setBaseDbLocal(String ip) async {

    _makeChangeOfIp(nameFilePathsP, ip);
    _makeChangeOfIp(nameFilePathsPS, ip);
  }

  ///
  static void _makeChangeOfIp(String fileNm, String ip) {

    File paths = File('${getPathRoot()}${getSep()}$fileNm');
    if (paths.existsSync()) {

      var mapa = Map<String, dynamic>.from(json.decode( paths.readAsStringSync() ));
      if (mapa.containsKey('server_local')) {
        if (mapa['server_local'].toString().contains('_ip_')) {
          mapa['server_local'] = mapa['server_local'].toString().replaceAll('_ip_', ip);
        }else{
          Uri uri = Uri.parse(mapa['server_local']);
          uri = uri.replace(host: ip);
          mapa['server_local'] = uri.toString();
        }
        paths.writeAsStringSync(json.encode(mapa));
      }
    }
  }

  /// Recuperamos la URI segun key desde el archivo de produccion
  static Directory? getPathsFolderTo(String key) {
    Directory? pathFolder = Directory('${getPathRoot()}${getSep()}$key');
    return pathFolder;
  }

  ///
  static Future<String> getFileByPath(String path) async {
    final paths = await _getFromFilePathsProd(path);
    if(paths.isNotEmpty) {
      return paths['uri'];
    }
    return '';
  }

  ///
  static Future<String> getDominio({bool isLocal = true}) async {

    isLocal = (env == 'dev') ? true : isLocal;
    
    final paths = await _getFromFilePathsProd('portServer');
    return (isLocal) ? paths['base_l'] : paths['base_r'];
  }

  ///
  static Future<Map<String, dynamic>> getConnectionFtp({bool isLocal = true}) async {

    isLocal = (env == 'dev') ? true : isLocal;

    final pathDt = await _getFromFilePathsProd('ftp');
    String sufix = (isLocal) ? 'l' : 'r';
    return {
      'url': pathDt['base_$sufix'],
      'u': pathDt['uri']['u'],
      'p': pathDt['uri']['p'],
      'ssl': true
    };
  }

  ///
  static Future<void> setDataConectionLocal() async {
    
    String path = await getFileByPath('harbi_connx');
    File file = File(path);
    var toWrite = await getBaseLocalAndRemoto();
    if(toWrite.containsKey('local')) {
      if(toWrite['local'] != globals.bdLocal) {
        toWrite['local'] = globals.bdLocal;
      }
    }
    if(toWrite.containsKey('remoto')) {
      if(toWrite['remoto'] != globals.bdRemota) {
        toWrite['remoto'] = globals.bdRemota;
      }
    }

    if(toWrite.containsKey('pto-loc')) {
      if(toWrite['pto-loc'] != globals.portdb) {
        toWrite['pto-loc'] = globals.portdb;
      }
    }
    file.writeAsStringSync(json.encode(toWrite));
  }

  ///
  static Future<Map<String, dynamic>> getBaseLocalAndRemoto() async {

    final paths = await _getFromFilePathsProd('portServer');

    return {
      'local': paths['base_l'],
      'remoto': paths['base_r'],
      'ipHarbi': globals.ipHarbi,
      'ptoHarbi': globals.portHarbi,
      'typeConx': globals.typeConn,
      'pto-loc': paths['uri'],
      'created': DateTime.now().toIso8601String()
    };
  }

  ///
  static Future<String> getUri(String uri, {bool isLocal = true}) async {

    isLocal = (env == 'dev') ? true : isLocal;

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);
    String base = '${uriPath['base_l']}${uriPath['uri']}/';
    if (!isLocal) {
      base = '${uriPath['base_r']}${uriPath['uri']}/';
    }
    return base;
  }

  ///
  static Future<String> getApi(String uri) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);
    return uriPath['uri'];
  }

  ///
  static Future<String> getPathToLogoMarcaOf(String marca,
    {bool isLocal = true}
  ) async {
    const carpeta = 'mrks_logos/';
    final dom = await getDominio(isLocal: isLocal);
    return '$dom$carpeta$marca';
  }

  ///
  static Future<Map<String, dynamic>> getContentFileOf(String path, {bool isTxt = false}) async {

    final paths = await _getFromFilePathsProd(path);
    
    final file = File(paths['uri']);
    if(file.existsSync()) {
      try {
        final content = (isTxt) ? file.readAsStringSync() : json.decode(file.readAsStringSync());
        return {'body': content};
      } catch (e) {
        // PrintScreen.alert(msg: e.toString());
      }
    }
    return {};
  }

}
