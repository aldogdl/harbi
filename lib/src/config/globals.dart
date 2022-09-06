
import 'package:flutter/material.dart' show Size;

import '../entity/conectado.dart';

class Globals {

  String harbiV  = '1.2.2';
  String harbiBin= '';
  double widMax = 0.73;
  double heiMax = 118.0;
  Size sizeWin = const Size(0, 0);

  // Colocar valor en segundos
  int revCada = 16;

  final String passH = '123H';
  
  String ipHarbi = '';
  int portHarbi = 8081;
  int portdb = 80;
  String wifiName = 'Oculto';
  String bdRemota= 'https://_dom_.com/';
  String bdLocal = 'http://_ip_:_port_/_dom_/public_html/';

  bool workOnlyLocal = false;
  List<Conectado> conectados = [];
  // Indica la ultima version del centinala obtenida
  String versionCentinela  = '';

}