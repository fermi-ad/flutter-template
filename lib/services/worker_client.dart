// Dart service that spawns the compiled Web Worker and handles the
// request/response message protocol.
//
// Usage
// -----
//   final client = WorkerClient();
//
//   // Parse a JSON string on the worker thread.
//   final dynamic result = await client.parseJson('{"key": "value"}');
//
//   // Release the worker when done.
//   client.dispose();
//
// The worker script must be compiled and served at the URL passed to the
// constructor (default: 'worker.dart.js').
//
// Using package:web + dart:js_interop keeps this WasmGC-compatible and
// avoids the deprecated dart:html API.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// A client that offloads JSON parsing to a dedicated Web Worker.
///
/// Each call to [parseJson] sends a JSON string to the worker, which decodes
/// it and returns the result asynchronously.  Multiple concurrent calls are
/// supported; each request is matched to its response via an integer id.
class WorkerClient {
  /// Creates a [WorkerClient] and immediately spawns the worker script at
  /// [workerUrl] (defaults to `'worker.dart.js'`).
  WorkerClient({final String workerUrl = 'worker.dart.js'}) {
    _worker = web.Worker(workerUrl);
    _worker.onmessage = _handleMessage.toJS;
    _worker.onerror = _handleError.toJS;
  }

  late final web.Worker _worker;

  final Map<int, Completer<dynamic>> _pending = {};
  int _nextId = 0;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sends [jsonString] to the worker for parsing and returns the decoded
  /// Dart value when the worker responds.
  ///
  /// Throws a [StateError] if the worker reports an error during processing.
  Future<dynamic> parseJson(final String jsonString) {
    final int id = _nextId++;
    final Completer<dynamic> completer = Completer<dynamic>();
    _pending[id] = completer;

    final String envelope = jsonEncode({'id': id, 'payload': jsonString});
    _worker.postMessage(envelope.toJS);

    return completer.future;
  }

  /// Terminates the underlying worker and cancels all pending requests.
  void dispose() {
    for (final Completer<dynamic> c in _pending.values) {
      c.completeError(StateError('WorkerClient disposed before response'));
    }
    _pending.clear();
    _worker.terminate();
  }

  // ---------------------------------------------------------------------------
  // Internal message handlers
  // ---------------------------------------------------------------------------

  void _handleMessage(final web.MessageEvent event) {
    int? id;
    try {
      final String raw = (event.data as JSString).toDart;
      final Map<String, dynamic> response =
          jsonDecode(raw) as Map<String, dynamic>;

      id = response['id'] as int;
      final Completer<dynamic>? completer = _pending.remove(id);

      if (completer == null) {
        // Response for an unknown or already-completed id (e.g. after dispose).
        // Nothing to do; this is expected if the client was disposed mid-flight.
        return;
      }

      if (response.containsKey('error')) {
        completer.completeError(
          StateError('Worker reported error: ${response['error']}'),
        );
      } else {
        completer.complete(response['result']);
      }
    } catch (e) {
      if (id != null) {
        _pending.remove(id)?.completeError(e);
      }
      // If id is unknown the response cannot be correlated; discard silently.
    }
  }

  void _handleError(final web.ErrorEvent event) {
    final String message = event.message;
    final StateError error = StateError('Worker error: $message');

    // Fail all pending requests on a worker-level error.
    for (final Completer<dynamic> c in _pending.values) {
      c.completeError(error);
    }
    _pending.clear();
  }
}
