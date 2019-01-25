import 'dart:convert';
import 'dart:io';
import 'package:events2/events2.dart';
import '../logger.dart';

const APP_NAME = 'protoo-client';
var logger = new Logger(APP_NAME);
const WS_SUBPROTOCOL = 'protoo';

// const DEFAULT_RETRY_OPTIONS = {
// 	retries    : 10,
// 	factor     : 2,
// 	minTimeout : 1 * 1000,
// 	maxTimeout : 8 * 1000
// };

class WebSocketTransport extends EventEmitter {
  var _url;
  var _ws;
  var _closed;
  JsonDecoder decoder = new JsonDecoder();
  JsonEncoder encoder = new JsonEncoder();

  WebSocketTransport(url) {
    logger.debug('constructor() [url:' + url + ']');
    // Save UR.
    this._url = url;
    // WebSocket instance.
    this._ws = null;
    // Closed flag.
    this._closed = false;
  }

  get closed => this._closed;

  Future<dynamic> send(message) async {
    if (this._closed) {
      throw 'transport closed';
    }
    try {
      logger.debug('send message: ' + encoder.convert(message));
      this._ws.add(encoder.convert(message));
      return message;
    } catch (error) {
      logger.failure('send() | error sending message: ' + error.toString());
    }
  }

  void close() {
    logger.debug('close()');

    if (this._closed) return;

    // Don't wait for the WebSocket 'close' event, do it now.
    this._closed = true;
    this.emit('close');
    try {
      this._ws.close();
    } catch (error) {
      logger.error('close() | error closing the WebSocket: ' + error);
    }
  }

  void connect() async {
    try {
      this._ws = await WebSocket.connect(this._url, headers: {
        'Sec-WebSocket-Protocol': WS_SUBPROTOCOL,
      });
      this._ws.listen((data) {
        logger.debug('Recivied data: ' + data);
        this.emit('message', decoder.convert(data));
      }, onDone: () {
        logger.debug('Closed by server!');
        this.emit('close');
      });
      this.emit('open');
    } catch (e) {
      this.emit('error', e.toString());
    }
  }
}
