import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bybit/bybit.dart';

void main() {
  test('Test klines subscription', () {
    ByBit bybit = ByBit();
    bybit.connect();
    bybit.subscribeToKlines(symbol: 'BTCUSD', interval: '1');
    bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
    StreamBuilder(
      stream: bybit.websocket.websocket.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var json = jsonDecode(snapshot.data);
          expect((json['data'] != null), true);
        }
        return Container();
      },
    );
  });
}
