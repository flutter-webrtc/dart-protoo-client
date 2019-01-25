import 'dart:math';

int min = 1000000;
int max = 9999999;

get randomNumber => min + (Random().nextInt(max - min));
