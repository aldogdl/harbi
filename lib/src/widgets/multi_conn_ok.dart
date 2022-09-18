import 'package:flutter/material.dart';

import '../config/my_theme.dart';
import '../config/sng_manager.dart';
import '../config/globals.dart';
import '../librerias/a_init_shell/test_conn.dart';
import '../providers/terminal_provider.dart';
import '../services/get_paths.dart';

/// Usado cuando se detectaron varias conexiones a la red local con Exito
/// Se le pedirá al usuario utilizar una de ellas como global y principal 
class MultiConnsOk extends StatefulWidget {
  
  final List<Map<String, dynamic>> conns;
  final TerminalProvider tprov;
  const MultiConnsOk({
    Key? key,
    required this.conns,
    required this.tprov
  }) : super(key: key);

  @override
  State<MultiConnsOk> createState() => _MultiConnsOkState();
}

class _MultiConnsOkState extends State<MultiConnsOk> {

  final _accions = ValueNotifier<String>('En Espera...');
  final _txtIp = TextEditingController();
  final _fcoIp = FocusNode();
  final _globals = getSngOf<Globals>();

  @override
  void dispose() {
    _txtIp.dispose();
    _accions.dispose();
    _fcoIp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        Expanded(flex: 6, child: _left()),
        const SizedBox(width: 20),
        Expanded(flex: 3, child: _right())
      ],
    );
  }

  ///
  Widget _left() {

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _texto(
                val: 'LISTA DE CONEXIONES ENCONTRADAS PARA:',
                size: 12, isBold: true
              ),
              const Divider(color: Colors.grey),
              _texto(
                val: _globals.wifiName,
                color: MyTheme.txtMain, isBold: true
              ),
              _texto(
                val: 'Selecciona una IP de las Conexiones dispobles o ingresa una nueva.',
                color: Colors.grey
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SizedBox(
            width: MediaQuery.of(context).size.height * 0.4,
            child: ListView(
              children: widget.conns.map((e) => _tileIp(e)).toList(),
            ),
          ),
        )
      ],
    );
  }

  ///
  Widget _tileIp(Map<String, dynamic> ips) {

    String tipo = ips['interface'];
    tipo = (tipo.length > 10) ? '${tipo.substring(0, 7)}...' : tipo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '[ ${ips['ip']} ] $tipo',
            textScaleFactor: 1,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.blue
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Seleccionar',
            child: IconButton(
              onPressed: (){
                _globals.ipHarbi = ips['ip'];
                _globals.typeConn = tipo;
                _globals.bdLocal  = 'http://${_globals.ipHarbi}:${_globals.portdb}/${GetPaths.package}/public_html/';
                _selecteIPdOfList();
              },
              icon: const Icon(Icons.check_circle_outline_outlined, color: Colors.green),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(0),
              iconSize: 18,
              constraints: const BoxConstraints(
                maxHeight: 15
              ),
            ),
          ),
          Tooltip(
            message: 'Probar IP',
            child: IconButton(
              onPressed: (){
                _globals.typeConn = tipo;
                setState(() {
                  _txtIp.text = ips['ip'];
                });
              },
              icon: const Icon(Icons.play_circle_outline, color: Colors.grey),
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              padding: const EdgeInsets.only(left: 15),
              constraints: const BoxConstraints(
                maxHeight: 15
              ),
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _right() {

    String hint = (_globals.ipHarbi.isEmpty) ? 'Ej. 192.168.1.70' : _globals.ipHarbi;
    
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _txtIp,
            focusNode: _fcoIp,
            autofocus: true,
            style: const TextStyle(
              color: MyTheme.txtMain,
              fontWeight: FontWeight.bold
            ),
            onSubmitted: (v) {
              _globals.typeConn = 'Personal';
              _hacerPrueba();
            },
            decoration: InputDecoration(
              border: _borde(),
              focusedBorder: _borde(color: Colors.blue),
              disabledBorder: _borde(),
              enabledBorder: _borde(),
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 17, color: Color.fromARGB(255, 82, 82, 82),
                fontWeight: FontWeight.w200
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
              suffixIcon: IconButton(
                onPressed: (){
                  setState(() {
                    _txtIp.text = '';
                  });
                },
                icon: const Icon(Icons.cleaning_services_rounded, color: Colors.grey),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: const EdgeInsets.only(left: 15, right: 15),
                constraints: const BoxConstraints(
                  maxHeight: 15
                ),
              )
            ),
          ),
        ),
        const SizedBox(height: 5),
        ValueListenableBuilder(
          valueListenable: _accions,
          builder: (_, val, child){
            if(val == 'En Espera...') {
              return child!;
            }
            return Text(
              val,
              textScaleFactor: 1,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 14
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _btnAcc('CANCELAR', () => Navigator.of(context).pop(false)),
              const SizedBox(width: 10),
              _btnAcc('INTERNAR CONEXIÓN', () => _hacerPrueba()),
            ],
          ),
        )
      ],
    );
  }
  
  ///
  Widget _btnAcc(String label, Function fnc) {

    Color bg = (label.startsWith('CAN'))
      ? MyTheme.bgSec : const Color.fromARGB(255, 43, 95, 45);

    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(bg)
      ),
      onPressed: () => fnc(),
      child: _texto(val: label, size: 14, color: MyTheme.txtMain)
    );
  }

  ///
  Widget _texto({
    required String val,
    Color color = Colors.orange, double size = 13, bool isBold = false })
  {

    return Text(
      val,
      textScaleFactor: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: (isBold) ? FontWeight.bold : FontWeight.normal
      ),
    );
  }

  ///
  OutlineInputBorder _borde({Color color = Colors.grey}) {

    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: color)
    );
  }

  /// Solicitamos una ip o dominio para hacer una prueba en caso de haber
  /// fallado todos lo intentos.
  Future<void> _hacerPrueba() async {

    final nav = Navigator.of(context);
    bool isOk = await _pbLocal();
    if(isOk) {
      _globals.bdLocal  = 'http://${_globals.ipHarbi}:${_globals.portdb}/${GetPaths.package}/public_html/';
      if(nav.canPop()) { nav.pop(true); }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 2000), (){
      _accions.value = 'En Espera...';
      _fcoIp.requestFocus();
    });
  }

  ///
  Future<bool> _pbLocal() async {

    if(_isValid()) {

      _accions.value = 'Haciendo Prueba, espera un momento...';
      await Future.delayed(const Duration(microseconds: 250));
      String ip = _txtIp.text.trim().toLowerCase();
      _globals.ipHarbi = ip;
      String res = await TestConn.local(widget.tprov);
      if(res == 'ok') {
        return await _accOk();
      }else{
        _accions.value = '[X] Error de conexión, Inténtalo nuevamente';
      }
    }

    _globals.ipHarbi = '';
    _globals.typeConn = '';
    return false;
  }

  ///
  Future<bool> _accOk() async {

    final res = '[√] Conexión ${_globals.ipHarbi} exitosa';
    _accions.value = res;
    widget.tprov.setAccs(res);
    await Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }

  ///
  void _selecteIPdOfList() async {

    final res = '[√] Seleccionada ${_globals.ipHarbi}.';
    _accions.value = res;
    widget.tprov.setAccs(res);
    final nav = Navigator.of(context);
    await Future.delayed(const Duration(milliseconds: 1000));
    if(nav.canPop()) { nav.pop(true); }
    return;
  }

  ///
  bool _isValid() {

    bool isOk = true;
    if(!_txtIp.text.contains('.')) {
      _accions.value = '[X] La IP ${_txtIp.text}, no es valida';
      isOk = false;
    }

    List<String> partes = _txtIp.text.split('.');
    if(partes.length < 4) {
      _accions.value = '[X] La IP ${_txtIp.text}, debe tener 4 fragmentos.';
      isOk = false;
    }

    return isOk;
  }
}