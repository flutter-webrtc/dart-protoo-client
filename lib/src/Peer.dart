import 'dart:async';
import 'package:events2/events2.dart';
import 'transports/WebSocketTransport.dart' show WebSocketTransport;
import 'Message.dart';
import 'logger.dart' show Logger;

// Max time waiting for a response.
const REQUEST_TIMEOUT = 20000;
var APP_NAME = 'protoo-client';

class Peer extends EventEmitter {
  var _socket;
  var _closed;
  var _data;
  var _url;
  Map<dynamic, dynamic> _requestHandlers;
  var logger = new Logger(APP_NAME);
  var _transport;

  Peer(url) {
    logger.debug('constructor()');

    // Transport.
    this._url = url;

    // Closed flag.
    this._closed = false;

    // Custom data object.
    this._data = {};

    this._transport = new WebSocketTransport(url);

    // Map of sent requests' handlers indexed by request.id.
    this._requestHandlers = new Map();

    // Handle transport.
    _handleTransport();
  }

  void connect() async {
    await this._transport.connect();
  }

  get data => this._data;

  set data(bool data) => this._data = data;

  get closed => this._closed;

  notify(method, data) {
    var notification = Message.notificationFactory(method, data);
    return this._transport.send(notification);
  }

  close() {
    logger.debug('close()');

    if (_closed) return;

    _closed = true;

    // Close transport.
    _transport.close();

    // Close every pending request handler.
    _requestHandlers.forEach((key, handler) {
      handler.close();
    });

    // Emit 'close' event.
    this.emit('close');
  }

  _handleTransport() {
    if (this._transport.closed) {
      this._closed = true;
      this.emit('close');
      return;
    }

    _transport.on('connecting', (currentAttempt) {
      logger.debug('emit "connecting" [currentAttempt:' + currentAttempt + ']');
      this.emit('connecting', currentAttempt);
    });

    _transport.on('open', () {
      if (_closed) return;
      logger.debug('emit "open"');
      // Emit 'open' event.
      this.emit('open');
    });

    _transport.on('disconnected', () {
      logger.debug('emit "disconnected"');

      this.emit('disconnected');
    });

    _transport.on('error', (currentAttempt) {
      logger.debug('emit "error" [currentAttempt:' + currentAttempt + ']');
      this.emit('error', currentAttempt);
    });

    _transport.on('close', () {
      if (this._closed) return;
      this._closed = true;
      logger.debug('emit "close"');
      // Emit 'close' event.
      this.emit('close');
    });

    this._transport.on('message', (message) {
      if (message['request'] != null && message['request'] == true) {
        _handleRequest(message);
      } else if (message['response'] != null && message['response'] == true) {
        _handleResponse(message);
      } else if (message['notification'] != null &&
          message['notification'] == true) {
        _handleNotification(message);
      }
    });
  }

  Future<dynamic> send(method, data) async {
    var completer = new Completer();
    var request = Message.requestFactory(method, data);
    try {
      this._transport.send(request).then((data) {
        var handler = {
          'resolve': (data2) {
            var handler = _requestHandlers[request['id']];
            if (handler == null)
              completer.completeError('Request handler is not in map!');
            handler['timer'].cancel();
            this._requestHandlers.remove(request['id']);
            completer.complete(data2);
          },
          'reject': (error) {
            var handler = _requestHandlers[request['id']];
            if (handler == null)
              completer.completeError('Request handler is not in map!');
            handler['timer'].cancel();
            this._requestHandlers.remove(request['id']);
            completer.completeError(error);
          },
          'timer': new Timer.periodic(
              new Duration(milliseconds: REQUEST_TIMEOUT),
                  (Timer timer) {
                timer.cancel();
                if (this._requestHandlers.remove(request['id']) == null)
                  completer.completeError('Request handler is not in map!');
                completer.completeError('request timeout');
              }),
          close: () {
            var handler = _requestHandlers[request['id']];
            if (handler == null)
              completer.completeError('Request handler is not in map!');
            handler['timer'].cancel();
            completer.completeError('peer closed');
          }
        };
        // Add handler stuff to the Map.
        this._requestHandlers[request['id']] = handler;
      });
    }catch(e) {
      completer.completeError('transport error');
    }
    return completer.future;
  }

  _handleRequest(request) {
    this.emit(
        'request',
        // Request.
        request,
        // accept() function.
        (data) {
      var response = Message.successResponseFactory(request, data);
      _transport.send(response).catchError((error) {
        logger.warn('accept() failed, response could not be sent: ' + error);
      });
    }, (errorCode, errorReason) {
      // reject() function.
      if (!(errorCode is num)) {
        errorReason = errorCode.toString();
        errorCode = 500;
      } else if (errorCode is num && errorReason is String) {
        errorReason = errorReason.toString();
      }

      var response =
          Message.errorResponseFactory(request, errorCode, errorReason);

      _transport.send(response).catchError((error) {
        logger.warn('reject() failed, response could not be sent: ' + error);
      });
    });
  }

  _handleResponse(response) {
    var handler = _requestHandlers[response['id']];
    if (handler == null) {
      logger.error('received response does not match any sent request');
      return;
    }

    if (response['ok'] != null && response['ok'] == true) {
      var resolve = handler['resolve'];
      resolve(response['data']);
    } else {
      var error = {
        'code': response['errorCode'] ?? 500,
        'error': response['errorReason'] ?? ''
      };
      var reject = handler['reject'];
      reject(error);
    }
  }

  _handleNotification(notification) {
    this.emit('notification', notification);
  }
}
