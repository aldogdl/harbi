import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

class GetIp {

  static final info = NetworkInfo();

  ///
  static Future<Map<String, dynamic>> search() async {

    Map<String, dynamic> interfaces = {};
    /// Recuperamos todas las interfaces existentes
    try {
      
      interfaces['wifiName'] = await info.getWifiName() ?? 'Oculta';
    } catch (_) {
      interfaces['wifiName'] = 'AutoparNet';
    }

    interfaces['interfaces'] = await _getAllInterfaces();
    return interfaces;
  }

  /// Si hay más de una interface de conección HARBI solicita con cual se
  /// conectan a internet, seleccionandola esta se guarda como la ip principal
  /// en la variable globals.
  static Future<List<Map<String, dynamic>>> _getAllInterfaces() async {

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
