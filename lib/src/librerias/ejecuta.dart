import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Ejecuta {

  ///
  static Future<void> exe(String executable, {List<String> args = const []}) async {

    final path = await _getPath(executable);
    await Process.start(
      path, args, runInShell: true, mode: ProcessStartMode.detached
    );
  }
  
  ///
  static Future<String> _getPath(String exe) async {

    final path = await getApplicationSupportDirectory();
    return p.join(path.path, 'bin', '$exe.exe');
  }
}