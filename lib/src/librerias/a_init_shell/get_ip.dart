import 'dart:io';

import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../providers/terminal_provider.dart';

import 'package:network_info_plus/network_info_plus.dart';

class GetIp {

  static final Globals _globals = getSngOf<Globals>();
  static final info = NetworkInfo();

  ///
  static Future<void> search(TerminalProvider proc) async {

    if(_globals.ipHarbi.isEmpty) {
      _globals.wifiName = await info.getWifiName() ?? 'Oculta';
      _globals.ipHarbi = await info.getWifiIP() ?? '';
    }

    if(_globals.ipHarbi.isEmpty) {
      await _buscar(proc);
    }
    if(_globals.ipHarbi.isNotEmpty) {
      proc.setAccs('[√] HARBI IP: ${_globals.ipHarbi} ACTUAL');
    }
  }

  /// Guardamos el las variables globales la ip de Harbi y el puerto
  static Future<void> _buscar(TerminalProvider proc) async {

    String subTitulo = '[X] Sin conexión a LAN';
    await _checkMutiplesInterfaces(proc);
    if(_globals.ipHarbi.isNotEmpty) {
      if(_globals.ipHarbi.contains('.')) {
        subTitulo = '[√] HARBI IP: ${_globals.ipHarbi} ACTUAL';
      }
    }
    proc.setAccs(subTitulo);
  }

  /// Si hay más de una interface de conección HARBI solicita con cual se
  /// conectan a internet, seleccionandola esta se guarda como la ip principal
  /// en la bariable globals.
  static Future<void> _checkMutiplesInterfaces(TerminalProvider proc) async {

    final conns = await NetworkInterface.list(
      includeLinkLocal: true,
      includeLoopback: true,
      type: InternetAddressType.IPv4
    );

    List<Map<String, dynamic>> findCon = [];
    conns.map((e) {
      if (e.addresses.first.rawAddress.first == 192) {
        findCon.add({
          'interface': e.name,
          'ip': e.addresses.first.address,
          'raw': e.addresses.first.rawAddress
        });
      }
    }).toList();

    if (findCon.length > 1) {
      List<String> ops = [];
      findCon.map((e) {
        if(!e['interface'].contains('VirtualBox')) {
          ops.add(e['interface']);
        }
      }).toList();

      if (ops.length > 1) {
        proc.setAccs('[!] Encontradas multiples Redes');
        // findCon = findCon.where(
        //   (element) => element['interface'] == result.value
        // ).toList();
      } else {
        findCon = findCon.where(
          (element) => element['interface'] == ops.first
        ).toList();
      }
    }
    
    if (findCon.isNotEmpty) {
      _globals.ipHarbi = findCon.first['ip'];
    }else{
      proc.setAccs('[X] No se detectó ningúna IP');
    }
  }

}
