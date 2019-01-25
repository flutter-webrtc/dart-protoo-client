import 'package:protoo_client/protoo_client.dart';

main() async {

  Peer peer = new Peer('ws://127.0.0.1:4442/?peer-id=xxxxx');

  peer.on('open', () {

    print('open');

    peer.send('login', {}).then((data) {
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
    reject(404, 'Oh no~~~~~');
  });

  await peer.connect();

  peer.close();
}
