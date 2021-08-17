import 'dart:async';

import 'EnhancedEventEmitter.dart';
import 'Logger.dart';
import 'Message.dart';
import 'transports/TransportInterface.dart';
export 'transports/NativeTransport.dart'
    if (dart.library.html) 'transports/WebTransport.dart';

final logger = new Logger('Peer');

class Peer extends EnhancedEventEmitter {
  // Closed flag.
  bool _closed = false;

  // Connected flag.
  bool _connected = false;

  // Custom data object.
  dynamic _data = {};

  // Map of pending sent request objects indexed by request id.
  var _sents = Map<String, dynamic>();

  // Transport.
  late TransportInterface _transport;

  Peer(TransportInterface transport) {
    _transport = transport;
    logger.debug('constructor()');
    _handleTransport();
  }

  /// Whether the Peer is closed.
  bool get closed => _closed;

  /// Whether the Peer is connected.
  bool get connected => _connected;

  /// App custom data
  dynamic get data => _data;

  close() {
    if (this._closed) return;

    logger.debug('close()');

    this._closed = true;
    this._connected = false;

    // close transport
    this._transport.close();

    // Close every pending sent.
    _sents.forEach((key, sent) {
      sent.close();
    });

    // Emit 'close' event.
    this.safeEmit('close');
  }

  /// Send a protoo request to the server-side Room.
  request(method, data) async {
    final completer = new Completer();
    final request = Message.createRequest(method, data);
    final requestId = request['id'].toString();
    logger.debug(
        'request() [method:' + method.toString() + ', id: ' + requestId + ']');

    // This may throw.
    await this._transport.send(request);

    int timeout = (1500 * (15 + (0.1 * this._sents.length))).toInt();
    final sent = {
      'id': request['id'],
      'method': request['method'],
      'resolve': (data2) {
        final sent = _sents.remove(requestId);
        if (sent == null) return;
        sent['timer'].cancel();
        completer.complete(data2);
      },
      'reject': (error) {
        final sent = _sents.remove(requestId);
        if (sent == null) return;
        sent['timer'].cancel();
        completer.completeError(error);
      },
      'timer': new Timer.periodic(new Duration(milliseconds: timeout),
          (Timer timer) {
        if (this._sents.remove(requestId) == null) return;

        completer.completeError('request timeout');
      }),
      'close': () {
        var handler = _sents[requestId];
        handler['timer'].cancel();
        completer.completeError('peer closed');
      }
    };

    _sents[requestId] = sent;
    return completer.future;
  }

  _handleTransport() {
    if (this._transport.closed) {
      this._closed = true;

      Future.delayed(Duration(seconds: 0), () {
        if (!_closed) {
          this._connected = false;

          this.safeEmit('close');
        }
      });

      return;
    }

    _transport.on('connecting', (currentAttempt) {
      logger.debug('emit "connecting" [currentAttempt:' + currentAttempt + ']');
      this.safeEmit('connecting', currentAttempt);
    });

    _transport.on('open', () {
      if (_closed) return;
      logger.debug('emit "open"');

      this._connected = true;

      this.safeEmit('open');
    });

    _transport.on('disconnected', () {
      if (_closed) return;
      logger.debug('emit "disconnected"');

      this._connected = false;

      this.safeEmit('disconnected');
    });

    _transport.on('failed', (currentAttempt) {
      if (_closed) return;
      logger.debug('emit "failed" [currentAttempt:' + currentAttempt + ']');

      this._connected = false;

      this.safeEmit('failed', currentAttempt);
    });

    _transport.on('close', () {
      if (this._closed) return;
      this._closed = true;
      logger.debug('emit "close"');

      this._connected = false;

      this.safeEmit('close');
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

  _handleRequest(request) {
    try {
      this.emit('request', request,
          // accept() function.
          ([data]) {
        final response = Message.createSuccessResponse(request, data ?? {});
        _transport.send(response).catchError((error) {
          logger.warn('accept() failed, response could not be sent: ' + error);
        });
      },
          // reject() function.
          (errorCode, errorReason) {
        if (!(errorCode is num)) {
          errorReason = errorCode.toString();
          errorCode = 500;
        } else if (errorCode is num && errorReason is String) {
          errorReason = errorReason.toString();
        }

        final response =
            Message.createErrorResponse(request, errorCode, errorReason);

        _transport.send(response).catchError((error) {
          logger.warn('reject() failed, response could not be sent: ' + error);
        });
      });
    } catch (error) {
      final response =
          Message.createErrorResponse(request, 500, error.toString());

      this._transport.send(response).catchError(() => {});
    }
  }

  _handleResponse(response) {
    final sent = _sents[response['id'].toString()];
    if (sent == null) {
      logger.error('received response does not match any sent request');
      return;
    }

    if (response['ok'] != null && response['ok'] == true) {
      var resolve = sent['resolve'];
      resolve(response['data']);
    } else {
      var error = {
        'code': response['errorCode'] ?? 500,
        'error': response['errorReason'] ?? ''
      };
      var reject = sent['reject'];
      reject(error);
    }
  }

  _handleNotification(notification) {
    this.safeEmit('notification', notification);
  }

  notify(method, data) {
    var notification = Message.createNotification(method, data);
    logger.debug('notify() [method:' + method + ']');
    return this._transport.send(notification);
  }
}
