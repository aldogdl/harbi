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
    if(p.context.current.endsWith('bin')) {
      path = '${p.context.current}${sep.first}..${sep.first}$folder';
    }else{
      path = '${p.context.current}${sep.first}$folder';
    }
    if(subFold.isNotEmpty) {
      subFold = '$subFold${sep.first}';
    }   
    return Directory('${p.context.normalize(path)}${sep.first}$subFold');
  }

  ///
  static Future<String> getContentAssetsBy(String file) async {
    
    return await rootBundle.loadString('assets/$file');
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
    return context.join(Platform.environment['APPDATA']!, 'com.$package');
  }

  /// Guardamos u obtenemos el tamaño de la pantalla del dispositivo
  static Future<Size> screen({String set = ''}) async {

    String root = getPathRoot();
    
    final file = File('$root${getSep()}screen.txt');
    if(file.existsSync()) {
      final setOld = file.readAsStringSync();
      if(setOld.isNotEmpty) {
        set = setOld;
      }else{
        if(set.isNotEmpty) {
          file.writeAsStringSync(set);
        }
      }
    }else{
      file.writeAsStringSync(set);
    }
    
    if(set.isNotEmpty) {
      final t = List<String>.from(set.split(' '));
      return Size(double.parse(t.first), double.parse(t.last));
    }
    return const Size(1280, 720);
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
    return paths['uri'];
  }

  ///
  static Future<String> getDominio({bool isLocal = true}) async {
    final paths = await _getFromFilePathsProd('portServer');
    return (isLocal) ? paths['base_l'] : paths['base_r'];
  }

  ///
  static Future<Map<String, dynamic>> getConnectionFtp({bool isLocal = true}) async {

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
  static Future<Map<String, dynamic>> getBaseLocalAndRemoto() async {

    final paths = await _getFromFilePathsProd('portServer');

    return {
      'local': paths['base_l'],
      'remoto': paths['base_r'],
      'ipHarbi': globals.ipHarbi,
      'ptoHarbi': globals.portHarbi,
      'pto-loc': paths['uri'],
    };
  }

  ///
  static Future<String> getUri(String uri, {bool isLocal = true}) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);

    String base = '${uriPath['base_l']}${uriPath['uri']}/';
    if (!isLocal) {
      base = '${uriPath['base_r']}${uriPath['uri']}/';
    }
    return base;
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
  static Future<Map<String, dynamic>> getContentFileOf(String path) async {

    final paths = await _getFromFilePathsProd(path);
    
    final file = File(paths['uri']);
    if(file.existsSync()) {
      try {
        final content = json.decode(file.readAsStringSync());
        return {'body': content};
      } catch (e) {
        // PrintScreen.alert(msg: e.toString());
      }
    }
    return {};
  }

}
