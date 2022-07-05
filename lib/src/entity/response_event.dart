import 'dart:convert';

class ResponseEvent {

  String event = '';
  String fnc = '';
  Map<String, dynamic> data = {};

  ResponseEvent({
    required this.event,
    required this.fnc,
    required this.data,
  });

  ///
  String toSend() {

    return json.encode({
      'event': event,
      'fnc': fnc,
      'data': data
    });
  }
}