import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:events2/events2.dart';
import 'websocket_dart_impl.dart';
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
  WebSocketImpl _ws;
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

  send(message) {
    if (this._closed) {
      throw 'transport closed';
    }
    try {
      logger.debug('send message: ' + encoder.convert(message));
      this._ws.send(encoder.convert(message));
    } catch (error) {
      logger.failure('send() | error sending message: ' + error.toString());
      throw error;
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
    logger.debug('connecting to WebSocket ${this._url}');
    try {
      this._ws = WebSocketImpl(this._url);

      this._ws.onOpen = () {
        _closed = false;
        this.emit('open');
      };

      this._ws.onMessage = (data) {
        logger.debug('Recivied data: ' + data);
        this.emit('message', decoder.convert(data));
      };

      this._ws.onClose = (closeCode, closeReason) {
        logger.debug('Closed by server!');
        this._closed = true;
        this.emit('close');
      };

      await this._ws.connect(headers: {});
    } catch (e) {
      this._closed = true;
      this.emit('error', e.toString());
    }
  }
}
