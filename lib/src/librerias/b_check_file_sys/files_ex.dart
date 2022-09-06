import 'dart:io';
import 'dart:convert';

import '../../services/get_paths.dart';

class FilesEx {

  /// Construimos archivos extras json dentro de assets
  static Future<void> crear() async {

    List<String> sep = [GetPaths.getSep()];

    //<---- CARGOS ---->
    var content = await GetPaths.getContentAssetsBy('cargos.json');
    if (content.isNotEmpty) {
      String path = await GetPaths.getFileByPath('cargos');
      File(path).writeAsStringSync(
        json.encode(json.decode(content))
      );
    }

    //<---- TESTINGS ---->
    content = await GetPaths.getContentAssetsBy('testings_scm.json');
    if (content.isNotEmpty) {
      String path = await GetPaths.getFileByPath('testings');
      File(path).writeAsStringSync(
        json.encode(json.decode(content))
      );
    }

    //<---- ROLES ---->
    content = await GetPaths.getContentAssetsBy('roles.json');
    if (content.isNotEmpty) {
      String path = await GetPaths.getFileByPath('roles');
      File(path).writeAsStringSync(
        json.encode(json.decode(content))
      );
    }

    //<---- MENSAJES CAMPAÑAS ---->
    await _buildMsgSCM(sep.first);
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

}
