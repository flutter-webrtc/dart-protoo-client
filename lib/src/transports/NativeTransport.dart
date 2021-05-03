import 'dart:convert';
import 'dart:io';

import '../Logger.dart';
import '../Message.dart';
import 'TransportInterface.dart';

final logger = Logger('Logger::WebTransport');

class NativeTransport extends TransportInterface {
  bool _closed;
  String _url;
  dynamic _options;
  WebSocket _ws;

  NativeTransport(String url, {dynamic options})
      : super(url, options: options) {
    logger.debug('constructor() [url:$url, options:$options]');
    this._closed = false;
    this._url = url;
    this._options = options ?? {};
    this._ws = null;

    this._runWebSocket();
  }

  get closed => _closed;

  @override
  close() {
    logger.debug('close()');

    this._closed = true;
    this.safeEmit('close');

    try {
      this._ws.close();
    } catch (error) {
      logger.error('close() | error closing the WebSocket: $error');
    }
  }

  @override
  Future send(message) async {
    try {
      this._ws.add(jsonEncode(message));
    } catch (error) {
      logger.warn('send() failed:$error');
    }
  }

  _onOpen() {
    logger.debug('onOpen');
    this.safeEmit('open');
  }

  // _onClose(event) {
  //   logger.warn(
  //       'WebSocket "close" event [wasClean:${e.wasClean}, code:${e.code}, reason:"${e.reason}"]');
  //   this._closed = true;

  //   this.safeEmit('close');
  // }

  _onError(err) {
    logger.error('WebSocket "error" event');
  }

  _runWebSocket() async {
    WebSocket.connect(this._url, protocols: ['protoo']).then((ws) {
      if (ws?.readyState == WebSocket.open) {
        this._ws = ws;
        _onOpen();

        ws.listen((event) {
          final message = Message.parse(event);

          if (message == null) return;

          this.safeEmit('message', message);
        }, onError: _onError);
      } else {
        logger.warn(
            'WebSocket "close" event code:${ws.closeCode}, reason:"${ws.closeReason}"]');
        this._closed = true;

        this.safeEmit('close');
      }
    });
    // this._ws.listen((e) {
    //   logger.debug('onOpen');
    //   this.safeEmit('open');
    // });

    // this._ws.onClose.listen((e) {
    //   logger.warn(
    //       'WebSocket "close" event [wasClean:${e.wasClean}, code:${e.code}, reason:"${e.reason}"]');
    //   this._closed = true;

    //   this.safeEmit('close');
    // });

    // this._ws.onError.listen((e) {
    //   logger.error('WebSocket "error" event');
    // });

    // this._ws.onMessage.listen((e) {
    //   final message = Message.parse(e.data);

    //   if (message == null) return;

    //   this.safeEmit('message', message);
    // });
  }
}
