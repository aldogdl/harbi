import 'dart:io';
import 'dart:convert';

import '../providers/terminal_provider.dart';
import '../services/get_paths.dart';

class MyPaths {

  /// Construimos los paths del sistema desde el archivo principal path
  static Future<void> crear(TerminalProvider proc) async {
    
    await _buildFolderRoot();
    Map<String, dynamic>? pathsFile = await GetPaths.getContentFilePaths();
    Map<String, dynamic>? pathsFileP = await GetPaths.getContentFilePaths(isProd: true);

    if (pathsFile != null) {
      if (pathsFileP != null) {
        if (pathsFileP.isNotEmpty) {
          if (pathsFileP['ver'] == pathsFile['ver']) {
            pathsFile = null;
          }
        }
      }
    }
    
    if (pathsFile == null) {
      proc.setAccs('[√] Sin cambios en Paths');
    }else{
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
    Map<String, dynamic> buildShare = await _replace(pathsP);

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
    for (String uri in pathsP['api_harbi']) {
      build[uri] = ':${build['portHarbi']}/api_harbi/$uri';
      buildShare[uri] = ':${buildShare['portHarbi']}/api_harbi/$uri';
    }
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

    build['portHarbi'] = data['portHarbi'];
    build['portServer'] = data['portServer'];
    build['portadas'] = data['portadas'];
    build['palcla'] = GetPaths.userShare;
    build['server_remote'] = data['bases_${GetPaths.env}']['server_remote'];
    build['server_local'] = data['bases_${GetPaths.env}']['server_local'];
    if (build['server_remote'].contains('_dom_')) {
      build['server_remote'] = build['server_remote'].replaceAll('_dom_', GetPaths.package);
    }
    if (build['server_remote'].contains('_port_')) {
      build['server_remote'] = build['server_remote'].replaceAll('_port_', '${data['portServer']}');
    }
    if (build['server_local'].contains('_dom_')) {
      build['server_local'] = build['server_local'].replaceAll('_dom_', GetPaths.package);
    }
    if (build['server_local'].contains('_port_')) {
      build['server_local'] = build['server_local'].replaceAll('_port_', '${data['portServer']}');
    }
    return build;
  }

}
