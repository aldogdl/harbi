import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:web_socket_channel/status.dart' as status;

import '../config/globals.dart';
import '../config/sng_manager.dart';

class SocketConn extends ChangeNotifier {

  final _globals = getSngOf<Globals>();

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

  /// Retorna true si la las variables de conexion estan correctas.
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
    if(idConn == -1) {
      idConn = 0;
    }
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

}
