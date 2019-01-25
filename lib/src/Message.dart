import 'utils.dart' as utils;
import 'logger.dart';
import 'dart:convert';

const APP_NAME = 'protoo-client';
var logger = new Logger(APP_NAME);

class Message
{
  static JsonEncoder encoder = new JsonEncoder();
  static JsonDecoder decoder = new JsonDecoder();

	static Future<String> parse(raw)
	{
		var object;
		var message;

		try
		{
			object = decoder.convert(raw);
		}
		catch (error)
		{
			logger.failure('parse() | invalid JSON: ' + error);
		}

		// if (typeof object !== 'object' || Array.isArray(object))
		// {
		// 	logger.error('parse() | not an object');

		// 	return;
		// }

		// Request.
		if (object['request'])
		{
			message['request'] = true;

      if(!(object['method'] is String)){
        logger.failure('parse() | missing/invalid method field');
      }

      if(!(object['id'] is num)){
        logger.failure('parse() | missing/invalid id field');
      }

			message['id'] = object['id'];
			message['method'] = object['method'];
			message['data'] = object['data'] ?? {};
		}
		// Response.
		else if (object['response'])
		{
			message['response'] = true;
      if(!(object['id'] is num)){
        logger.failure('parse() | missing/invalid id field');
      }

			message['id'] = object['id'];

			// Success.
			if (object['ok'])
			{
				message['ok'] = true;
				message['data'] = object['data'] ?? {};
			}
			// Error.
			else
			{
				message['errorCode'] = object['errorCode'];
				message['errorReason'] = object['errorReason'];
			}
		}
		// Notification.
		else if (object['notification'])
		{
			message['notification'] = true;
      if(!(object['method'] is String)){
        logger.failure('parse() | missing/invalid method field');
      }

			message['method'] = object['method'];
			message['data'] = object['data'] ?? {};
		}else {
			logger.failure('parse() | missing request/response field');
		}

		return message;
	}

	static requestFactory(method, data)
	{
		var requestObj =
		{
			'request' : true,
			'id'      : utils.randomNumber,
			'method'  : method,
			'data'    : data ?? {}
		};

		return requestObj;
	}

	static successResponseFactory(request, data)
	{
		var responseObj =
		{
			'response' : true,
			'id'       : request['id'],
			'ok'       : true,
			'data'    : data ?? {}
		};

		return responseObj;
	}

	static errorResponseFactory(request, errorCode, errorReason)
	{
		var responseObj =
		{
			'response'    : true,
			'id'       : request['id'],
			'errorCode'   : errorCode,
			'errorReason' : errorReason
		};

		return responseObj;
	}

	static notificationFactory(method, data)
	{
		var notificationObj =
		{
			'notification' : true,
			'method'       : method,
			'data '       : data ?? {},
		};

		return notificationObj;
	}
}
