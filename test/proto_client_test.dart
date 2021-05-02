import 'package:protoo_client/protoo_client.dart';
import 'package:protoo_client/src/transports/WebTransport.dart';

final url = 'wss://v3demo.mediasoup.org:4443';
final roomId = 'asdasdds';
final peerId = 'zxcvvczx';

main() async {
  Peer peer = new Peer(WebTransport('$url/?roomId=$roomId&peerId=$peerId'));

  peer.on('open', () {
    print('open');

    peer.request('method', 'getRouterRtpCapabilities').then((data) {
      print('response: ' + data.toString());
    }).catchError((error) {
      print('response error: ' + error.toString());
    });
  });

  peer.on('close', () {
    print('close');
  });

  peer.on('error', (error) {
    print('error ' + error);
  });

  peer.on('request', (request, accept, reject) {
    print('request: ' + request.toString());
    accept({'key1': "value1", 'key2': "value2"});
    //reject(404, 'Oh no~~~~~');
  });

  //await peer.connect();

  //peer.close();
}
