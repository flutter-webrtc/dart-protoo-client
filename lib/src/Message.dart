import 'utils.dart' as utils;
import 'package:logging/logging.dart';
import 'dart:convert';

const APP_NAME = 'protoo-client';
var logger = new Logger(APP_NAME);


class Message
{
	static parse(raw)
	{
		var object;
		var message = {};

		try
		{
			object = JSON.decode(raw);
		}
		catch (error)
		{
			logger.error('parse() | invalid JSON: %s', error);

			return;
		}

		// if (typeof object !== 'object' || Array.isArray(object))
		// {
		// 	logger.error('parse() | not an object');

		// 	return;
		// }

		// Request.
		if (object.request)
		{
			message.request = true;

			// if (typeof object.method !== 'string')
			// {
			// 	logger.error('parse() | missing/invalid method field');

			// 	return;
			// }
      if(!(object.method is String)){
        logger.error('parse() | missing/invalid method field');

				return;
      }

			// if (typeof object.id !== 'number')
			// {
			// 	logger.error('parse() | missing/invalid id field');

			// 	return;
			// }

      if(!(object.id is double)){
        logger.error('parse() | missing/invalid id field');

				return;
      }

			message.id = object.id;

			message.method = object.method;
			message.data = object.data || {};
		}
		// Response.
		else if (object.response)
		{
			message.response = true;

			// if (typeof object.id !== 'number')
			// {
			// 	logger.error('parse() | missing/invalid id field');

			// 	return;
			// }
      if(!(object.id is double)){
        logger.error('parse() | missing/invalid id field');
				return;
      }
      

			message.id = object.id;

			// Success.
			if (object.ok)
			{
				message.ok = true;
				message.data = object.data || {};
			}
			// Error.
			else
			{
				message.errorCode = object.errorCode;
				message.errorReason = object.errorReason;
			}
		}
		// Notification.
		else if (object.notification)
		{
			message.notification = true;

			// if (typeof object.method !== 'string')
			// {
			// 	logger.error('parse() | missing/invalid method field');

			// 	return;
			// }
      if(!(object.method is String)){
        logger.error('parse() | missing/invalid method field');

				return;
      }

			message.method = object.method;
			message.data = object.data || {};
		}
		// Invalid.
		else
		{
			logger.error('parse() | missing request/response field');

			return;
		}

		return message;
	}

	static requestFactory(method, data)
	{
		var requestObj =
		{
			request : true,
			id      : utils.randomNumber(),
			method  : method,
			data    : data || {}
		};

		return requestObj;
	}

	static successResponseFactory(request, data)
	{
		var responseObj =
		{
			response : true,
			id       : request.id,
			ok       : true,
			data     : data || {}
		};

		return responseObj;
	}

	static errorResponseFactory(request, errorCode, errorReason)
	{
		var responseObj =
		{
			response    : true,
			id          : request.id,
			errorCode   : errorCode,
			errorReason : errorReason
		};

		return responseObj;
	}

	static notificationFactory(method, data)
	{
		var notificationObj =
		{
			notification : true,
			method       : method,
			data         : data || {}
		};

		return notificationObj;
	}
}
