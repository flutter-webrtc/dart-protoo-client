import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import '../logger.dart';

typedef void OnMessageCallback(dynamic msg);
typedef void OnCloseCallback(int code, String reason);
typedef void OnOpenCallback();

class WebSocketImpl {
  String _url;
  var _socket;
  final logger = Logger('Logger::Dart::WebSocket');
  OnOpenCallback onOpen;
  OnMessageCallback onMessage;
  OnCloseCallback onClose;
  WebSocketImpl(this._url);

  connect({Object protocols, Object headers}) async {
    logger.debug('connect $_url, $headers, $protocols');
    try {
     // _socket =
     //     await WebSocket.connect(_url, protocols: protocols, headers: headers);

      _socket = await _connectForBadCertificate(_url);

      this?.onOpen();
      _socket.listen((data) {
        this?.onMessage(data);
      }, onDone: () {
        this?.onClose(_socket.closeCode, _socket.closeReason);
      });
    } catch (e) {
      this.onClose(_socket.closeCode, _socket.closeReason);
    }
  }

  send(data) {
    if (_socket != null) {
      _socket.add(data);
      logger.debug('send: $data');
    }
  }

  close() {
    _socket.close();
  }

  isConnecting() {
    return _socket != null && _socket.readyState == WebSocket.connecting;
  }

  /// For test only.
  Future<WebSocket> _connectForBadCertificate(url) async {
    try {
      Random r = new Random();
      String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
      SecurityContext securityContext = new SecurityContext();
      HttpClient client = HttpClient(context: securityContext);
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        logger.warn('Allow self-signed certificate => $host:$port. ');
        return true;
      };

      HttpClientRequest request = await client.getUrl(Uri.parse(url)); // form the correct url here

      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add('Sec-WebSocket-Protocol', 'protoo');
      request.headers.add(
          'Sec-WebSocket-Version', '13'); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());

      HttpClientResponse response = await request.close();
      var socket = await response.detachSocket();
      var webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'protoo',
        serverSide: false,
      );

      return webSocket;
    } catch (e) {
      logger.error('error $e');
      throw e;
    }
  }
}
