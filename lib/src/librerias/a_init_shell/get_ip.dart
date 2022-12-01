import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../services/get_paths.dart';

class GetIp {

  static final info = NetworkInfo();
  static Globals globals = getSngOf<Globals>();

  ///
  static Future<Map<String, dynamic>> search() async {

    Map<String, dynamic> interfaces = {};
    /// Recuperamos todas las interfaces existentes
    try {
      interfaces['wifiName'] = await info.getWifiName() ?? 'Oculta';
    } catch (_) {
      interfaces['wifiName'] = 'AutoparNet';
    }

    final res = await _getAllInterfaces();
    if(res.first.containsKey('created')) {
      interfaces['recovery'] = res.first;
    }else{
      interfaces['interfaces'] = res;
    }
    return interfaces;
  }

  /// Si hay más de una interface de conección HARBI solicita con cual se
  /// conectan a internet, seleccionandola esta se guarda como la ip principal
  /// en la variable globals.
  static Future<List<Map<String, dynamic>>> _getAllInterfaces() async {

    // Revisamos si las conecciones actuales estan vigentes.
    final current = await GetPaths.getContentFileOf('harbi_connx');
    if(current.isNotEmpty) {
      if(current.containsKey('body')) {
      
        if(current['body'].containsKey('created')) {
          final hoy = DateTime.now();
          final make = DateTime.parse(current['body']['created']);
          final diff = make.difference(hoy);
          if(diff.inHours < globals.timeScanIps) {
            return [current['body']];
          }
        }
      }
    }

    final conns = await NetworkInterface.list(
      includeLinkLocal: true,
      includeLoopback: false,
      type: InternetAddressType.IPv4
    );

    late String ipWi;
    try {
      ipWi = await info.getWifiIP() ?? '';
    } catch (_) {
      ipWi = '';
    }

    List<Map<String, dynamic>> maines = [];

    conns.map((e) {

      if(e.name.startsWith('Ethernet')) {
        maines.add({
          'interface': e.name,
          'ip': e.addresses.first.address,
          'raw': e.addresses.first.rawAddress
        });
      }

      if(e.name.startsWith('Wi')) {

        if(ipWi.isNotEmpty) {
          if(e.addresses.first.address.trim() != ipWi.trim()) {
            maines.add({
              'interface': 'Wi-Fi 2',
              'ip': ipWi,
              'raw': ipWi.split('.')
            });
          }
        }

        maines.add({
          'interface': e.name,
          'ip': e.addresses.first.address,
          'raw': e.addresses.first.rawAddress
        });
      }

    }).toList();

    // En ocaciones el Wifi no es detectado por medio de la lista de interfaces
    // para ello hacemos una ultima corroboración de su existencia.
    final hasWiFi = maines.where(
      (element) => element['interface'].startsWith('Wi')
    );

    if(hasWiFi.isEmpty) {
      if(ipWi.isNotEmpty) {
        maines.add({
          'interface': 'Wi-Fi',
          'ip': ipWi,
          'raw': ipWi.split('.')
        });
      }
    }

    return maines;
  }

}
