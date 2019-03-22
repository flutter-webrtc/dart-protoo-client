[![pub package](https://img.shields.io/pub/v/protoo_client.svg)](https://pub.dartlang.org/packages/protoo_client)

# protoo-client
Dart version of the [protoo-client](https://github.com/ibc/protoo/tree/master/client) js library.

Minimalist and extensible Dart signaling framework for multi-party Real-Time Communication applications

## Usage

``` dart


import 'package:protoo_client/protoo_client.dart';

main() async {

  Peer peer = new Peer('ws://127.0.0.1:4442/?peer-id=yourId');

  peer.on('open', () {
    // After socket open to send a request.
    peer.send('login', {'username':'myname','password','mypass', 'other': {}})
    .then((data) {
      // Handle accept from server.
      print('response: ' + data.toString());
    }).catchError((error) {
      // Handle reject from server.
      print('response error: ' + error.toString());
    });
  });

  peer.on('close', () {
    print('close');
  });

  peer.on('error', (error) {
    print('error ' + error);
  });
 
  // Handle request from server.
  peer.on('request', (request, accept, reject) {
    print('request: ' + request.toString());
    reject(486, 'Busy Here!!!');
  });

  await peer.connect();
  peer.close();
}

```
