
import 'package:flutter/material.dart' show Size;

import '../entity/conectado.dart';

class Globals {

  String env  = 'dev';
  String harbiV  = '2.0.0';
  // Colocar valor en segundos
  int revCada = 8;

  String swh = '';
  String harbiBin= '';
  double widMax = 0.73;
  double heiMax = 118.0;
  Size sizeWin = const Size(0, 0);
  // Tiempo que debe trasncurrir en horas para volver a escanear las ip de RED
  int timeScanIps = 2;

  String ipHarbi = '';
  String typeConn = '';
  int portHarbi = 8081;
  int portdb = 80;
  String wifiName = 'Oculto';
  String bdRemota= 'https://_dom_.com/';
  String bdLocal = 'http://_ip_:_port_/_dom_/public_html/';
  List<Conectado> conectados = [];
  // Indica la ultima version del centinala obtenida
  String versionCentinela  = '';

}