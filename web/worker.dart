// Entry point for the dedicated Web Worker.
//
// Compile this file separately (e.g. `dart compile js -o web/worker.dart.js
// web/worker.dart`) so the browser can load it as a Worker script.
//
// Protocol
// --------
// Incoming message  – a JSON string whose outer envelope is:
//   { "id": <int>, "payload": "<escaped JSON string to parse>" }
//
// Outgoing success  – a JSON string:
//   { "id": <int>, "result": <parsed value> }
//
// Outgoing error  – a JSON string:
//   { "id": <int>, "error": "<message>" }
//
// Using package:web + dart:js_interop keeps this WasmGC-compatible and
// avoids the deprecated dart:html API.

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

// Access the DedicatedWorkerGlobalScope via the JS global `self`.
@JS('self')
external web.DedicatedWorkerGlobalScope get _self;

void main() {
  _self.onmessage = _handleMessage.toJS;
}

void _handleMessage(web.MessageEvent event) {
  int? id;
  try {
    final raw = (event.data as JSString).toDart;

    final Map<String, dynamic> request =
        jsonDecode(raw) as Map<String, dynamic>;
    id = request['id'] as int;
    final String payload = request['payload'] as String;

    final dynamic parsed = jsonDecode(payload);

    _self.postMessage(jsonEncode({'id': id, 'result': parsed}).toJS);
  } catch (e) {
    if (id != null) {
      _self.postMessage(jsonEncode({'id': id, 'error': e.toString()}).toJS);
    }
    // If id could not be determined the request cannot be matched; the
    // WorkerClient will time out or the caller will handle via its own timeout.
  }
}
