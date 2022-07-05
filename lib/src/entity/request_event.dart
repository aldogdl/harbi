import 'dart:convert';

class RequestEvent {

  String event = '';
  String fnc = '';
  Map<String, dynamic> data = {};

  RequestEvent({
    required this.event,
    required this.fnc,
    this.data = const {},
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