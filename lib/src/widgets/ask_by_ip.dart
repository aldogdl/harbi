import 'package:flutter/material.dart';

import '../config/my_theme.dart';
import '../config/sng_manager.dart';
import '../config/globals.dart';
import '../librerias/a_init_shell/test_conn.dart';
import '../providers/terminal_provider.dart';

class AskByIp extends StatefulWidget {
  
  final String tipo;
  final TerminalProvider tprov;
  const AskByIp({
    Key? key,
    required this.tipo,
    required this.tprov
  }) : super(key: key);

  @override
  State<AskByIp> createState() => _AskByIpState();
}

class _AskByIpState extends State<AskByIp> {

  final ValueNotifier<String> _accions = ValueNotifier('En espera...');
  final TextEditingController _txtIp = TextEditingController();
  final _globals = getSngOf<Globals>();

  @override
  void dispose() {
    _txtIp.dispose();
    _accions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        Expanded(flex: 4, child: _left()),
        const SizedBox(width: 20),
        Expanded(flex: 3, child: _right())
      ],
    );
  }

  ///
  Widget _left() {

    final dom = (widget.tipo == 'local') ? 'IP' : 'URL';

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _texto(
          val: 'INGRESA UNA NUEVA $dom VALIDA, POR FAVOR',
          size: 15, isBold: true
        ),
        const Divider(color: Colors.grey),
        _texto(
          val: 'HARBI, tratará reconectar con la $dom ingresada buscándo que sea valida',
          color: MyTheme.txtMain
        ),
        ValueListenableBuilder<String>(
          valueListenable: _accions,
          builder: (_, val, __) {

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(val.startsWith('[-]'))
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 10),
                _texto(
                  val: val,
                  color: (val.startsWith('[X]')) ? Colors.amber : Colors.blue
                )
              ],
            );
          }
        )
      ],
    );
  }

  ///
  Widget _right() {

    String hint = _globals.ipHarbi;
    if(widget.tipo == 'local') {
      if(hint.isEmpty) {
        hint = 'Ej. 192.168.1.74';
      }else{
        hint = 'Ej. $hint';
      }
    }else{
      hint = 'Escribe "local", para continuar sin REMOTO.';
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _txtIp,
            autofocus: true,
            style: const TextStyle(
              color: MyTheme.txtMain,
              fontWeight: FontWeight.bold
            ),
            onEditingComplete: () => _hacerPrueba(),
            onSubmitted: (v) => _hacerPrueba(),
            decoration: InputDecoration(
              border: _borde(),
              focusedBorder: _borde(color: Colors.blue),
              disabledBorder: _borde(),
              enabledBorder: _borde(),
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14, color: Color.fromARGB(255, 102, 102, 102)
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
            mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _btnAcc('CANCELAR', () => Navigator.of(context).pop(false)),
            const SizedBox(width: 10),
            _btnAcc('INTERNAR CONEXIÓN', () => _hacerPrueba()),
          ],
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
    Color color = Colors.orange, double size = 13, bool isBold = false
  }) {

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
    _accions.value = '[-] Haciendo Prueba con: ${_txtIp.text}';
    await Future.delayed(const Duration(milliseconds: 200));

    bool isOk = (widget.tipo == 'local') ? await _pbLocal() : await _pbRemota();
    if(isOk) {
      if(nav.canPop()) { nav.pop(true); }
      return;
    }
    
    _accions.value = '[X] Error de conexión, Inténtalo nuevamente';
  }

  ///
  Future<bool> _pbRemota() async {    

    String ip = _txtIp.text.trim().toLowerCase();
    if (ip == 'local') {
      _accions.value = 'HARBI, trabajarará sólo de manera LOCAL';
      widget.tprov.setAccs('[√] Trabajando de manera local');
      _globals.workOnlyLocal = true;
      _globals.bdRemota= 'https://_dom_.com/';
      await Future.delayed(const Duration(milliseconds: 3000));
      return true;
    }

    if(_isValid()) {
      if(!ip.startsWith('http')) { ip = 'https://$ip/'; }
      _globals.bdRemota = ip;
      String res = await TestConn.remota(widget.tprov);
      if(res == 'ok') { return _accOk(); }
    }

    _globals.bdRemota = 'https://_dom_.com/';
    return false;
  }

  ///
  Future<bool> _pbLocal() async {

    if(_isValid()) {
      String ip = _txtIp.text.trim().toLowerCase();
      if(!ip.startsWith('http')) { ip = 'http://$ip/'; }
      _globals.ipHarbi = ip;
      String res = await TestConn.local(widget.tprov);
      if(res == 'ok') { return _accOk(); }
    }
    _globals.ipHarbi = '';

    return false;
  }

  ///
  bool _accOk() {

    final res = '[√] Conexión ${widget.tipo} exitosa';
    _accions.value = res;
    widget.tprov.setAccs(res);
    Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }

  ///
  bool _isValid() {

    final dom = (widget.tipo == 'local') ? 'IP' : 'URL';
    if(!_txtIp.text.contains('.')) {
      _accions.value = '[X] La $dom ${_txtIp.text}, no es valida';
      return false;
    }
    return true;
  }
}