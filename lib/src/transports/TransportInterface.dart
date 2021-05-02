import 'dart:io';

import '../EnhancedEventEmitter.dart';

abstract class TransportInterface extends EnhancedEventEmitter {
  TransportInterface(String url, {dynamic options}) : super();

  get closed;

  Future send(dynamic message);

  close();
}
