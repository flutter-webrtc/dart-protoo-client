import 'package:event_emitter/event_emitter.dart';
import 'package:logging/logging.dart';
import 'Message.dart';
import 'transports/WebSocketTransport.dart';


var events  = new EventEmitter();
const APP_NAME = 'protoo-client';
var logger = new Logger(APP_NAME);


// Max time waiting for a response.
const REQUEST_TIMEOUT = 20000;

class Peer{

  WebSocketTransport _transport;
  var _closed;
  var _data;
  var _requestHandlers;

	Peer(transport){
		logger.debug('constructor()');

		
		//this.setMaxListeners(Infinity);

		// Transport.
		this._transport = transport;

		// Closed flag.
		this._closed = false;

		// Custom data object.
		this._data = {};

		// Map of sent requests' handlers indexed by request.id.
		this._requestHandlers = new Map();

		// Handle transport.
		_handleTransport();
	}

	// get data()
	// {
	// 	return this._data;
	// }

	// set data(obj)
	// {
	// 	this._data = obj || {};
	// }

	// get closed(){
	// 	return _closed;
	// }

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

	notify(method, data){
		var notification = Message.notificationFactory(method, data);

		return this._transport.send(notification);
	}

	close(){
		logger.debug('close()');

		if (_closed)
			return;

		_closed = true;

		// Close transport.
		_transport.close();

		// Close every pending request handler.
		_requestHandlers.forEach((handler) => handler.close());

		// Emit 'close' event.
		events.emit('close');
	}

	_handleTransport(){
		if (this._transport.closed){
			this._closed = true;
			//setTimeout(() => events.emit('close'));
      //events.emit('close');
			return;
		}

		// _transport.on('connecting', (currentAttempt){
		// 	logger.debug('emit "connecting" [currentAttempt:%s]', currentAttempt);
		// 	events.emit('connecting', currentAttempt);
		// });

    this._transport.onStateChange = (state){

      switch (state) {
          case ConnectState.Connecting:
            break;
          case ConnectState.Open:
            break;
          case ConnectState.Disconnected:
            break;
          case ConnectState.Close:
            if (this._closed){
              return;
            }
            this._closed = true;
            logger.debug('emit "close"');
            break;
          case ConnectState.Failed:
            break;
        }
    };
    

    

		// _transport.on('open', (){
		// 	if (_closed)
		// 		return;

		// 	logger.debug('emit "open"');

		// 	// Emit 'open' event.
		// 	events.emit('open');
		// });

		// _transport.on('disconnected', () =>
		// {
		// 	logger.debug('emit "disconnected"');

		// 	events.emit('disconnected');
		// });

		// _transport.on('failed', (currentAttempt) =>
		// {
		// 	logger.debug('emit "failed" [currentAttempt:%s]', currentAttempt);

		// 	events.emit('failed', currentAttempt);
		// });

		// _transport.on('close', (){
		// 	if (this._closed)
		// 		return;

		// 	this._closed = true;

		// 	logger.debug('emit "close"');

		// 	// Emit 'close' event.
		// 	events.emit('close');
		// });

    this._transport.onMessage = (message){
      if (message.request){
          _handleRequest(message);
        }
        else if (message.response){
          _handleResponse(message);
        }
        else if (message.notification){
          _handleNotification(message);
        }
    };
	}

	_handleRequest(request)
	{
		// events.emit('request',
		// 	// Request.
		// 	request,
		// 	// accept() function.
		// 	(data) =>
		// 	{
		// 		var response = Message.successResponseFactory(request, data);

		// 		_transport.send(response)
		// 			.catch((error) =>
		// 			{
		// 				logger.warn(
		// 					'accept() failed, response could not be sent: %o', error);
		// 			});
		// 	},
		// 	// reject() function.
		// 	(errorCode, errorReason) =>
		// 	{
		// 		if (errorCode instanceof Error)
		// 		{
		// 			errorReason = errorCode.toString();
		// 			errorCode = 500;
		// 		}
		// 		else if (typeof errorCode === 'number' && errorReason instanceof Error)
		// 		{
		// 			errorReason = errorReason.toString();
		// 		}

		// 		var response =
		// 			Message.errorResponseFactory(request, errorCode, errorReason);

		// 		_transport.send(response)
		// 			.catch((error) =>
		// 			{
		// 				logger.warn(
		// 					'reject() failed, response could not be sent: %o', error);
		// 			});
		// 	});
	}

	_handleResponse(response)
	{
		// const handler = _requestHandlers.get(response.id);

		// if (!handler)
		// {
		// 	logger.error('received response does not match any sent request');

		// 	return;
		// }

		// if (response.ok)
		// {
		// 	handler.resolve(response.data);
		// }
		// else
		// {
		// 	const error = new Error(response.errorReason);

		// 	error.code = response.errorCode;
		// 	handler.reject(error);
		// }
	}

	_handleNotification(notification){
		events.emit('notification', notification);
	}
}