import 'package:flutter/foundation.dart' show ChangeNotifier;

class TerminalProvider extends ChangeNotifier {

  // Usada para refrescar la seccion de conectados
  bool refreshConectados = true;
  void setRefreshConectados(bool refresh) {
    refreshConectados = refresh;
    notifyListeners();
  }
  
  // Si es necesario notificar a los conectados de un cambio del centinela
  bool requiredNotiff = false;
  int cantChecks = 0;
  DateTime lastCheck = DateTime.now();

  ///
  int isTime(DateTime now) {
    final diff = now.difference(lastCheck);
    return diff.inSeconds;
  }

  ///
  String _secc = 'check';
  String get secc => _secc;
  set secc(String seccion) {
    _secc = seccion;
    notifyListeners();
  }

  List<String> accs = [];
  void setAccs(String accsion) {
    var tmp = List<String>.from(accs);
    String isNotif = '';
    if(tmp.length > 29) {
      if(tmp.first.startsWith('[^]')) {
        isNotif = tmp.first;
      }
      tmp = [];
    }
    accs = [];
    tmp.insert(0, accsion);
    if(isNotif.isNotEmpty) {
      tmp.add(isNotif);
    }
    accs = List<String>.from(tmp);
    tmp = [];
    notifyListeners();
  }
}