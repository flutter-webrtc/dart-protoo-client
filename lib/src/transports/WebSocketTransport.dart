import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:event_emitter/event_emitter.dart';
import 'package:logging/logging.dart';
import '../Message.dart' as Message;

var events  = new EventEmitter();
const APP_NAME = 'protoo-client';
var logger = new Logger(APP_NAME);

// const W3CWebSocket = require('websocket').w3cwebsocket;
// const retry = require('retry');


// const WS_SUBPROTOCOL = 'protoo';
// const DEFAULT_RETRY_OPTIONS = {
// 	retries    : 10,
// 	factor     : 2,
// 	minTimeout : 1 * 1000,
// 	maxTimeout : 8 * 1000
// };

enum ConnectState {
  Connecting,
  Open,
  Close,
  Disconnected,
  Failed,
}



typedef void ConnectCallback(ConnectState state);
typedef void MessageCallback(Message msg);

class WebSocketTransport{

  var _url;
  var _options;
  var _ws;
  var _closed;
  var _socket;

  ConnectCallback onStateChange;
  MessageCallback onMessage;

	WebSocketTransport(url, options){
		logger.debug('constructor() [url:"%s", options:%o]', url, options);

		//this.setMaxListeners(Infinity);

		// Save URL and options.
		this._url = url;
		this._options = options || {};

		// WebSocket instance.
		this._ws = null;

		// Closed flag.
		this._closed = false;

		// Set WebSocket
		this._setWebSocket();
	}

	// get closed()
	// {
	// 	return this._closed;
	// }

	send(message){
		if (this._closed){
      //return Promise.reject(new Error('transport closed'));
      return 'transport closed';
    }

		try{
			this._ws.send(JSON.stringify(message));

			//return Promise.resolve();
      return "success";
		}
		catch (error){
			logger.error('send() | error sending message: %o', error);

			//return Promise.reject(error);
      return 'error';
		}
	}

	void close(){
		logger.debug('close()');

		if (this._closed)
			return;

		// Don't wait for the WebSocket 'close' event, do it now.
		this._closed = true;
		this.emit('close');

		try{
			this._ws.onopen = null;
			this._ws.onclose = null;
			this._ws.onerror = null;
			this._ws.onmessage = null;
			this._ws.close();
		}
		catch (error)
		{
			logger.error('close() | error closing the WebSocket: %o', error);
		}
	}


/*
	_setWebSocket()
	{
		const options = this._options;
		const operation = retry.operation(this._options.retry || DEFAULT_RETRY_OPTIONS);
		let wasConnected = false;

		operation.attempt((currentAttempt) =>
		{
			if (this._closed){
				operation.stop();

				return;
			}

			logger.debug('_setWebSocket() [currentAttempt:%s]', currentAttempt);

			this._ws = new W3CWebSocket(
				this._url,
				WS_SUBPROTOCOL,
				options.origin,
				options.headers,
				options.requestOptions,
				options.clientConfig
			);

			this.emit('connecting', currentAttempt);

			this._ws.onopen = () =>
			{
				if (this._closed)
					return;

				wasConnected = true;

				// Emit 'open' event.
				this.emit('open');
			};

			this._ws.onclose = (event) =>
			{
				if (this._closed)
					return;

				logger.warn('WebSocket "close" event [wasClean:%s, code:%s, reason:"%s"]',
					event.wasClean, event.code, event.reason);

				// Don't retry if code is 4000 (closed by the server).
				if (event.code !== 4000)
				{
					// If it was not connected, try again.
					if (!wasConnected)
					{
						this.emit('failed', currentAttempt);

						if (this._closed)
							return;

						if (operation.retry(true))
							return;
					}
					// If it was connected, start from scratch.
					else
					{
						operation.stop();

						this.emit('disconnected');

						if (this._closed)
							return;

						this._setWebSocket();

						return;
					}
				}

				this._closed = true;

				// Emit 'close' event.
				this.emit('close');
			};

			this._ws.onerror = () =>
			{
				if (this._closed)
					return;

				logger.error('WebSocket "error" event');
			};

			this._ws.onmessage = (event) =>
			{
				if (this._closed)
					return;

				const message = Message.parse(event.data);

				if (!message)
					return;

				if (this.listenerCount('message') === 0)
				{
					logger.error('no listeners for WebSocket "message" event, ignoring received message');

					return;
				}

				// Emit 'message' event.
				this.emit('message', message);
			};
		});

*/


    void connect() async {
    try {
      _socket = await WebSocket.connect('');

      if (this.onStateChange != null) {
        this.onStateChange('');
      }

      _socket.listen((data) {
        print('Recivied data: ' + data);
        JsonDecoder decoder = new JsonDecoder();
        this.onMessage(decoder.convert(data));
      }, onDone: () {
        print('Closed by server!');
        if (this.onStateChange != null) {
          this.onStateChange('');
        }
      });

      // _send('new', {
      //   'name': _name,
      //   'id': _selfId,
      //   'user_agent': 'flutter-webrtc/'+ Platform.operatingSystem +'-plugin 0.0.1'
      // });
    }catch(e){
      if(this.onStateChange != null){
        this.onStateChange('');
      }
    }
  }
  
}
