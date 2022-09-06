import 'dart:io';
import 'dart:convert';

import 'package:harbi/src/apis_server/rutas/rutas_api.dart';
import 'package:harbi/src/config/sng_manager.dart';

import '../../config/globals.dart';
import '../../providers/terminal_provider.dart';
import '../../services/get_paths.dart';

class MyPaths {

  static final _globals = getSngOf<Globals>();
  
  /// Construimos los paths del sistema desde el archivo principal path
  static Future<void> crear(TerminalProvider proc) async {
    
    await _buildFolderRoot();
    Map<String, dynamic>? pathsFile = await GetPaths.getContentFilePaths();
    Map<String, dynamic>? pathsFileP = await GetPaths.getContentFilePaths(isProd: true);

    if (pathsFile != null) {
      if (pathsFileP != null) {
        if (pathsFileP.isNotEmpty) {
          
          if ('${pathsFileP['ver']}' == '${pathsFile['ver']}') {
            
            proc.setAccs('[!] Corroborando Ip y Url');
            bool save = await _checkDataConnect(GetPaths.nameFilePathsP);
            if(save) {
              await _checkDataConnect(GetPaths.nameFilePathsPS);
            }
            proc.setAccs('[√] Chequeo Ip y Url Exitoso');
            pathsFile = null;
          }
        }
      }
    }
    
    if (pathsFile == null) {
      proc.setAccs('[√] Sin cambios en Paths');
    }else{
      
      if(!_globals.ipHarbi.contains('.')) {
        await Future.delayed(const Duration(milliseconds: 1000));
        proc.setAccs('[X] No hay una IP asignada');
        return;
      }
      proc.setAccs('[-] Reconstruyendo Paths');
      await Future.delayed(const Duration(milliseconds: 1000));
      await _make(pathsFile);
      proc.setAccs('[√] Paths Construidas');
    }
  }

  ///
  static Future<void> _buildFolderRoot() async {

    String root = GetPaths.getPathRoot();
    Directory? dirRoot = Directory(root);
    if (!dirRoot.existsSync()) {
      dirRoot.create();
    }
  }

  ///
  static Future<void> _make(Map<String, dynamic> pathsP) async {

    List<String> sep = [GetPaths.getSep()];
    
    Map<String, dynamic> build = await _replace(pathsP);
    Map<String, dynamic> buildShare = Map<String, dynamic>.from(build);

    String myAppData = GetPaths.getPathRoot();
    String appData = GetPaths.getPathRootShare();

    //<---- FOLDERS ---->
    Map<String, dynamic>.from(pathsP['folders_base']).forEach((key, value) {
      Directory dirShare = Directory('$myAppData${sep.first}$value');
      if (!dirShare.existsSync()) {
        dirShare.createSync();
      }
    });

    //<---- ARCHIVOS ---->
    pathsP['files'].forEach((key, value) {
      final partes = value.split('::');
      String path = '';
      if (partes.length > 2) {
        path = '${pathsP[partes.first][partes[1]]}${sep.first}${partes.last}';
      } else {
        path = '${partes.last}';
      }
      File f = File('$myAppData${sep.first}$path');
      if (!f.existsSync()) {
        f.createSync();
      }
      build[key] = '$myAppData${sep.first}$path';
      buildShare[key] = '$appData${sep.first}$path';
    });

    //<---- FTP ---->
    build['ftp'] = pathsP['ftp'];
    buildShare['ftp'] = pathsP['ftp'];

    //<---- URIS ---->
    for (String uri in pathsP['uris']) {
      if (uri.contains('::')) {
        final partes = uri.split('::');
        final prefix = pathsP['prefix_uris'][partes.first];
        final uriKey = partes.last.replaceAll('-', '_');
        build[uriKey] = '$prefix${partes.last}';
        buildShare[uriKey] = '$prefix${partes.last}';
      }
    }

    //<---- URIS INTERNAS PARA LA API DE HARBI ---->
    const api = RutasApi.api;
    for (String uri in pathsP[api]) {
      build[uri] = '$api/$uri';
      buildShare[uri] = '$api/$uri';
    }

    //<---- GUARDAMOS LOS ARCHIVOS RESULTANTES ---->
    String path = '$myAppData${sep.first}${GetPaths.nameFilePathsP}';
    File paths = File(path);
    paths.writeAsStringSync(json.encode(build));
    paths.createSync();

    path = '$myAppData${sep.first}${GetPaths.nameFilePathsPS}';
    paths = File(path);
    paths.writeAsStringSync(json.encode(buildShare));
    paths.createSync();
    return;
  }

  ///
  static Future<Map<String, dynamic>> _replace(Map<String, dynamic> data) async {

    var build = <String, dynamic>{'ver': data['ver']};

    build['portadas'] = data['portadas'];
    build['portHarbi'] = _globals.portHarbi;
    build['portServer'] = _globals.portdb;
    build['palcla'] = GetPaths.userShare;
    build['ip_harbi'] = _globals.ipHarbi;
    build['server_remote'] = _globals.bdRemota;
    if(build['server_remote'].contains('_dom_')) {
      build['server_remote'] = build['server_remote'].replaceAll('_dom_', GetPaths.package);
    }
    build['server_local'] = _globals.bdLocal;
    
    return build;
  }

  ///
  static Future<bool> _checkDataConnect(String filename) async {

    bool save = false;
    Map<String, dynamic> current = {};

    List<String> sep = [GetPaths.getSep()];
    File arch = File('${GetPaths.getPathRoot()}${sep.first}$filename');
    if (arch.existsSync()) {
      current = Map<String, dynamic>.from(json.decode(arch.readAsStringSync()));
    }

    if(current.isNotEmpty) {

      if(current.containsKey('server_remote')) {
        if(current['server_remote'] != _globals.bdRemota) {
          if(_globals.bdRemota.contains(GetPaths.package)) {
            current['server_remote'] = _globals.bdRemota;
            save = true;
          }
        }
      }

      if(current.containsKey('server_local')) {
        if(current['server_local'] != _globals.bdLocal) {
          if(_globals.bdLocal.contains(GetPaths.package)) {
            current['server_local'] = _globals.bdLocal;
            save = true;
          }
        }
      }

      if(current.containsKey('ip_harbi')) {
        if(current['ip_harbi'] != _globals.ipHarbi) {
          current['ip_harbi'] = _globals.ipHarbi;
          save = true;
        }
      }

      if(save) {
        arch.writeAsStringSync(json.encode(current));
      }
    }

    return save;
  }
}
