import 'dart:core';
import 'package:events2/events2.dart';


class MyClass extends EventEmitter{
  MyClass(){}

  void sendEvent(){
    this.emit('event2', 'a', 'b', 3, 'd');
  }
}

main() {
  MyClass event_emitter = new MyClass();
  event_emitter.on('event1', (a, String b, int c, d) {
    print('a = ' +
        a +
        ', b = ' +
        b +
        ', c = ' +
        c.toString() +
        ', d = ' +
        d.toString());
  });

  event_emitter.once('event2', () {
    print('event2 ');
  });

  event_emitter.on('event3', (a) {
    print('event3 ');
  });

  event_emitter.on('event3', (a, b) {
    print('event322 ');
  });

  event_emitter.emit('event1', 'a', 'b', null);
  event_emitter.emit('event3', 'a', 'b', 3, 'd');
  event_emitter.sendEvent();
  event_emitter.off('event1');
}
