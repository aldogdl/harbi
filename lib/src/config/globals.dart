
import 'package:flutter/material.dart' show Size;

import '../entity/conectado.dart';

class Globals {

  Size sizeWin = const Size(0, 0);
  final String passH = '123H';
  String ipHarbi = '';
  int portHarbi = 8081;
  String wifiName = 'Oculto';
  // Colocar valor en segundos
  int revCada = 16;
  String bdLocal = '';
  String bdRemota = '';
  bool workOnlyLocal = false;
  List<Conectado> conectados = [];
  // Indica la ultima version del centinala obtenida
  String versionCentinela  = '';

}