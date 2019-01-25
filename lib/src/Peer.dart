import 'dart:convert';
import 'dart:async';
import 'dart:io';
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

    // Map of sent requests' handlers indexed by request.id.
    this._requestHandlers = new Map();

    this._transport = WebSocketTransport(url);

    // Handle transport.
    _handleTransport();
  }

  get data => this._data;

  set data(bool data) => this._data = data;

  get closed => this._closed;

  // send(method, data)
  // {
  // 	var request = Message.requestFactory(method, data);

  // 	return this._transport.send(request)
  // 		.then(() =>
  // 		{
  // 			return new Promise((pResolve, pReject) =>
  // 			{
  // 				const handler =
  // 				{
  // 					resolve : (data2) =>
  // 					{
  // 						if (!_requestHandlers.delete(request.id))
  // 							return;

  // 						clearTimeout(handler.timer);
  // 						pResolve(data2);
  // 					},

  // 					reject : (error) =>
  // 					{
  // 						if (!_requestHandlers.delete(request.id))
  // 							return;

  // 						clearTimeout(handler.timer);
  // 						pReject(error);
  // 					},

  // 					timer : setTimeout(() =>
  // 					{
  // 						if (!_requestHandlers.delete(request.id))
  // 							return;

  // 						pReject(new Error('request timeout'));
  // 					}, REQUEST_TIMEOUT),

  // 					close : () =>
  // 					{
  // 						clearTimeout(handler.timer);
  // 						pReject(new Error('peer closed'));
  // 					}
  // 				};

  // 				// Add handler stuff to the Map.
  // 				_requestHandlers.set(request.id, handler);
  // 			});
  // 		});
  // }

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
      //setTimeout(() => events.emit('close'));
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

    _transport.on('failed', (currentAttempt) {
      logger.debug('emit "failed" [currentAttempt:' + currentAttempt + ']');
      this.emit('failed', currentAttempt);
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

  clearTimeout(handler) {}

  setTimeout(handler, timeout) {}

  Future<dynamic> send(method, data) async {
    var request = Message.requestFactory(method, data);

    this._transport.send(request).then(() {
      var handler = {
        'resolve': (data2) {
          if (!this._requestHandlers.remove(request['id'])) return null;

          clearTimeout(_requestHandlers[request['id']]['timer']);

          return data2;
        },
        'reject': (error) {
          if (!this._requestHandlers.remove(request['id'])) return;

          clearTimeout(_requestHandlers[request['id']]['timer']);
          throw (error);
        },
        'timer': setTimeout(() {
          if (!this._requestHandlers.remove(request['id'])) return;

          throw ('request timeout');
        }, REQUEST_TIMEOUT),
        close: () {
          clearTimeout(_requestHandlers[request['id']]['timer']);
          throw ('peer closed');
        }
      };
      // Add handler stuff to the Map.
      this._requestHandlers[request['id']] = handler;
    });
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
      if (errorCode is num) {
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

    if (!handler) {
      logger.error('received response does not match any sent request');
      return;
    }

    if (response['ok']) {
      handler.resolve(response['data']);
    } else {
      var error = {
        'code': response['errorCode'],
        'error': response['errorReason']
      };
      handler.reject(error);
    }
  }

  _handleNotification(notification) {
    this.emit('notification', notification);
  }
}
