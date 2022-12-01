import 'dart:io';
import 'dart:convert';

import '../../services/get_paths.dart';

class FilesEx {

  /// Construimos archivos extras json dentro de assets
  static Future<void> crear() async {

    List<String> sep = [GetPaths.getSep()];

    //<---- ESTACIONES DE TRABAJOS ---->
    String content = '';
    try {
      content = await GetPaths.getContentAssetsBy('harbis.json');
      if (content.isNotEmpty) {
        String path = await GetPaths.getFileByPath('harbis');
        if(path.isNotEmpty) {
          File(path).writeAsStringSync(
            json.encode(json.decode(content))
          );
        }
      }
    } catch (e) {
      setLog('[files_ex::crear::harbis.json] -> ${e.toString()}');
    }
    
    //<---- CARGOS ---->
    try {
      content = await GetPaths.getContentAssetsBy('cargos.json');
      if (content.isNotEmpty) {
        String path = await GetPaths.getFileByPath('cargos');
        File(path).writeAsStringSync(
          json.encode(json.decode(content))
        );
      }
    } catch (e) {
      setLog('[files_ex::crear::cargos.json] -> ${e.toString()}');
    }
    
    //<---- TESTINGS ---->
    try {
      content = await GetPaths.getContentAssetsBy('testings_scm.json');
      if (content.isNotEmpty) {
        String path = await GetPaths.getFileByPath('testings');
        File(path).writeAsStringSync(
          json.encode(json.decode(content))
        );
      }
    } catch (e) {
      setLog('[files_ex::crear::testings_scm.json] -> ${e.toString()}');
    }
    
    //<---- ROLES ---->
    try {
      content = await GetPaths.getContentAssetsBy('roles.json');
      if (content.isNotEmpty) {
        String path = await GetPaths.getFileByPath('roles');
        File(path).writeAsStringSync(
          json.encode(json.decode(content))
        );
      }
    } catch (e) {
      setLog('[files_ex::crear::roles.json] -> ${e.toString()}');
    }
    

    //<---- MENSAJES CAMPAÑAS ---->
    try {
      await _buildMsgSCM(sep.first);
    } catch (e) {
      setLog('[files_ex::crear::_buildMsgSCM] -> ${e.toString()}');
    }
    
  }

  ///
  static Future<void> _buildMsgSCM(String sep) async {

    final pathMsgs = GetPaths.getPathsFolderTo('scm_msgs');
    if(pathMsgs != null) {

      final assets = GetPaths.getDirectoryAssets(subFold: 'scm_msgs');
      if(assets.existsSync()) {

        final nuevos = assets.listSync();
        if(nuevos.length > 1) {

          final msgs = pathMsgs.listSync().toList();
          if(msgs.isNotEmpty) {
            msgs.map((f) => f.deleteSync()).toList();
          }
          for (var i = 0; i < nuevos.length; i++) {
            Uri uri = Uri.file(nuevos[i].path);
            final nom = uri.pathSegments.last;
            File msgF = File(nuevos[i].path);
            if(msgF.existsSync()) {
              msgF.copySync('${pathMsgs.path}$sep$nom');
            }
          }
        }
      }
    }
  }

  ///
  static void setLog(String msgErr) {

    final logP = GetPaths.getPathsFolderTo('logs');
    if(logP != null && logP.existsSync()) {

      List<String> content = [];
      String f = 'create_extras_errors.json';
      final file = File('${logP.path}${ GetPaths.getSep() }$f');
      if(file.existsSync()) {
        final txt = file.readAsStringSync();
        if(txt.isNotEmpty) {
          content = List<String>.from(json.decode(txt));
        }
      }
      content.add(msgErr);
      file.writeAsStringSync(json.encode(content));
    }
  }
}
