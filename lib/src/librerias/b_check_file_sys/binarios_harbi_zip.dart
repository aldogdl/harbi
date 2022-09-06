import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:harbi/src/config/globals.dart';
import 'package:harbi/src/config/sng_manager.dart';

import '../../services/get_paths.dart';

class BinariosHarbi {

  static final _globals = getSngOf<Globals>();

  /// <---- BINARIOS ---->
  static Future<String> check() async {

    final pathToAsset = GetPaths.getDirectoryAssets();
    File fzip = File('${pathToAsset.path}/bin.zip');

    if (fzip.existsSync()) {
      final path = GetPaths.getPathsFolderTo('harbi');
      if(path != null) {
        final dirBin = Directory('${path.path}/bin');
        if(!dirBin.existsSync()) {
          dirBin.createSync();
        }
        final archivosBin = fzip.readAsBytesSync();
        final files = ZipDecoder().decodeBytes(archivosBin);
        for (final file in files) {

          final filename = file.name;
          if(file.isFile) {
            final data = file.content as List<int>;
            File('${dirBin.path}/$filename')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);

            if(filename.endsWith('.txt')) {
              final fileV = File('${dirBin.path}/$filename');
              if(fileV.existsSync()) {
                final version = fileV.readAsStringSync();
                _globals.harbiBin = version.trim();
              }
            }
          }
        }
      }

    }else{
      _globals.harbiBin = 'Inexistentes';
      return '[X] Archivos Binarios Inexistentes';
    }

    return '[√] Archivos Binarios Listos';
  }

}
