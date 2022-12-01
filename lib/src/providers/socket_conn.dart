import 'dart:convert';
import 'dart:io';

import 'package:cron/cron.dart';
import 'package:harbi/src/services/get_paths.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:web_socket_channel/status.dart' as status;

import '../config/globals.dart';
import '../config/sng_manager.dart';
import '../librerias/f_cron_centinela/conectados_check.dart';

class SocketConn extends ChangeNotifier {

  final _globals = getSngOf<Globals>();

  String _sep = '';
  String _pathInPush = '';
  String _pathOutPush = '';
  String _pathLogs = '';

  Cron _checkInPush = Cron();
  int _cantInPush = 0;
  int get cantInPush => _cantInPush;
  set cantInPush(int cant) {
    _cantInPush = cant;
    notifyListeners();
  }
  Future<void> cancelCronInPush() async {
    await _checkInPush.close();
  }

  IOWebSocketChannel? _socket;
  IOWebSocketChannel get socket => _socket!;

  bool _isConectedSocked = false;
  bool get isConnectedSocked => _isConectedSocked;
  set isConnectedSocked(bool connected) {
    _isConectedSocked = connected;
    notifyListeners();
  }

  ///
  int _idConn = 0;
  int get idConn => _idConn;
  set idConn(int conn) {
    _idConn = conn;
    notifyListeners();
  }

  // Usada para refrescar la seccion de conectados
  bool refreshConectados = true;
  void setRefreshConectados(bool refresh) {
    refreshConectados = refresh;
    notifyListeners();
  }

  ///
  String event = '';

  List<String> _sockmsg = [];
  List<String> get sockmsg => _sockmsg;
  cleanSockmsg() => _sockmsg = [];
  setSockmsg(String msg) {
    var tmp = List<String>.from(sockmsg);
    _sockmsg = [];
    tmp.insert(0, msg);
    _sockmsg = List<String>.from(tmp);
    tmp = [];
    notifyListeners();
  }

  ///
  void cerrarConection() {
    isConnectedSocked = false;
    idConn = 0;
    close();
  }

  ///
  void close() {
    if (_socket != null) {
      _socket!.sink.close(status.normalClosure);
    }
    isConnectedSocked = false;
    _socket == null;
  }

  /// Retorna true si las variables de conexion estan correctas.
  bool checkConeccion() {

    bool isCon = isConnectedSocked;

    if (_socket == null) {
      isCon = false;
    } else {
      if (_socket!.innerWebSocket != null) {
        if (_socket!.innerWebSocket!.readyState == 3) {
          isCon = false;
        }
      } else {
        isCon = false;
      }
    }
    return isCon;
  }

  ///
  void send() async {

    if(event.isEmpty){ return; }
    try {
      _socket!.sink.add(event);
      event = '';
    } catch (e) {
      setSockmsg('Se desconectó HARBI');
      return;
    }
  }

  ///
  Future<bool> makeFirstConnection() async {

    const intentos = 3;
    const espera = 1000;
    int intents = 1;
    await _conectar();
    do {
      await Future.delayed(const Duration(milliseconds: espera));
      if(idConn == 0) {
        if(intents == intentos) {
          idConn = -1;
        }
        intents++;
      }
    } while (idConn == 0);

    if(idConn == -1) { idConn = 0; }
    return false;
  }

  ///
  Future<void> _conectar() async {

    setSockmsg('> Contactando Sistema');
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      _socket = IOWebSocketChannel.connect(
        Uri.parse('ws://${_globals.ipHarbi}:${_globals.portHarbi}/socket')
      );
    } catch (e) {
      setSockmsg('[X] Error al Intentar conectar el Sistema');
      return;
    }

    setSockmsg('[!] Esperando Respuesta de Conexión');
    await Future.delayed(const Duration(milliseconds: 1000));

    _socket!.stream.listen((event) {
      isConnectedSocked = true;
      _determinarEvento(Map<String, dynamic>.from(json.decode(event)));
    });
  }

  ///
  Future<void> _determinarEvento(Map<String, dynamic> response) async {

    if (response.containsKey('connId')) {
      idConn = response['connId'];
      setSockmsg('[√] Conexión Establecida');
      return;
    }
    if (response.containsKey('event')) {
      return;
    }

    cerrarConection();
  }

  /// ----------------------- NOTIFICACIONES ---------------------------------
  
  ///
  Future<void> initCheckInPush() async {

    try {
      _checkInPush.schedule(Schedule.parse('*/3 * * * * *'), () async {
        _goCheckInPush();
      });
    } catch (e) {
      if(e.toString().contains('Close')) {
        _checkInPush = Cron();
        await Future.delayed(const Duration(milliseconds: 500));
        initCheckInPush();
      }else{
        // setAccs('[X] ${e.toString()}');
      }
    }
  }

  ///
  Future<void> _goCheckInPush() async {

    if(_pathInPush.isEmpty) {
      _sep = GetPaths.getSep();
      var path1 = GetPaths.getPathsFolderTo('pushin');
      var path2 = GetPaths.getPathsFolderTo('pushout');
      var path3 = GetPaths.getPathsFolderTo('logs');
      if(path1 != null) {
        _pathInPush = '${path1.path}$_sep';
      }
      if(path2 != null) {
        _pathOutPush = '${path2.path}$_sep';
      }
      if(path3 != null) {
        _pathLogs = '${path3.path}$_sep';
      }
      path1 = null;
      path2 = null;
      path3 = null;
    }

    cantInPush = (cantInPush +1);
    final dir = Directory(_pathInPush).listSync().toList();
    if(dir.isNotEmpty) {

      List<String> sendAll = [];
      for (var i = 0; i < dir.length; i++) {

        String filen = dir[i].path.split(_sep).last;
        if(filen.startsWith('fire_push')) {
          dir[i].renameSync('$_pathLogs$filen');
          continue;
        }

        // Si la notificacion tiene -t4 es el tercer intento, por lo tanto es
        // enviada a lostPush
        if(filen.contains('-t4')) {
          _sendLostPush(dir[i]);
          continue;
        }

        // En ambos casos se solicita la notificacion por 
        if(filen.startsWith('to-')) {
          // Enviarle la notificacion a un determinado id.
        }else{
          // Enviarle la notificacion a todos.
          filen = _changeNameToFile(filen);
          sendAll.add(filen);
        }

        dir[i].renameSync('$_pathOutPush$filen');
      }

      if(sendAll.isNotEmpty) {
        if(_socket != null) {
          event = 'pushall%${sendAll.join(',')}';
          send();
        }
      }

      // Al finalizar los envios esperamos 15 segundos para dar oportunidad a los
      // receptores recojan sus respectivo mensaje, pasando estos 15 segundos
      // revisamos la carpeta de "outpush" y si no esta bacia recorremos
      // dicha carpeta y pasamos todos los archivos a la carpeta "inpush".
      Future.delayed(const Duration(milliseconds: 15000), () async {
        await _goCheckOutPush();
      });
    }
    
    // Checamos quien esta actualmente en conexion con harbi.
    ConectadosCheck.checarMiembrosConectados(this);
  }

  ///
  String _changeNameToFile(String filename) {

    // Al enviar la notificacion esta es pasada a la carpeta de "outpush"
    if(!filename.contains('-t')) {
      filename = filename.replaceAll('.json', '-t1.json');
    }
    return filename;
  }

  ///
  Future<void> _goCheckOutPush() async {

    final dir = Directory(_pathOutPush).listSync().toList();
    if(dir.isNotEmpty) {

      for (var i = 0; i < dir.length; i++) {

        String filen = dir[i].path.split(_sep).last;
        if(filen.contains('-t1.json')) {
          filen = filen.replaceAll('-t1.json', '-t2.json');
        }else{
          if(filen.contains('-t2.json')) {
            filen = filen.replaceAll('-t2.json', '-t3.json');
          }else{
            if(filen.contains('-t3.json')) {
              filen = filen.replaceAll('-t3.json', '-t4.json');
            }
          }
        }
        // Al enviar la notificacion esta es pasada a la carpeta de sended
        dir[i].renameSync('$_pathInPush$filen');
      }
    }
  }

  ///
  void _sendLostPush(FileSystemEntity file) {

    final path = GetPaths.getPathsFolderTo('pushlost');
    String filen = file.path.split(_sep).last;
    if(filen.contains('-t4.json')) {
      filen = filen.replaceAll('-t4.json', '.json');
    }

    if(filen.startsWith('centinela_update')) {
      filen = 'centinela_update-push_notification.json';
    }
    file.renameSync('${path!.path}$_sep$filen');
  }
}