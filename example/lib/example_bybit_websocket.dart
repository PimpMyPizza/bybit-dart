import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

class ExampleByBitWebSocket extends StatefulWidget {
  @override
  _ExampleByBitWebSocketState createState() => _ExampleByBitWebSocketState();
}

class _ExampleByBitWebSocketState extends State<ExampleByBitWebSocket> {
  @override
  Widget build(BuildContext context) {
    ByBit bybit = ByBit.getInstance();
    bybit.subscribeToKlines(symbol: 'ETHUSD', interval: '1');
    bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
    bybit.subscribeToOrderBook(depth: 25);
    return StreamBuilder(
      stream: bybit.websocket.websocket.stream,
      builder: (context, bybitResponse) {
        // Handle the bybit response here
        if (bybitResponse.hasData && bybitResponse.data != null) {
          print('From WebSocket: ' + bybitResponse.data.toString());
          return Container(child: Text(bybitResponse.data));
        } else {
          return Container();
        }
      },
    );
  }
}
