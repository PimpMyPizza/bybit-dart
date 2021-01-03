import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

/// Just a contains that shows the outputs of the ByBit websocket
class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ByBit bybit = ByBit(websocketUrl: 'wss://stream.bytick.com/realtime');
    bybit.connect();
    bybit.subscribeToKlines(symbol: 'ETHUSD', interval: '1');
    bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
    bybit.subscribeToOrderBook(depth: 25);
    return StreamBuilder(
      stream: bybit.websocket.stream,
      builder: (context, bybitResponse) {
        // Handle the bybit response here
        if (bybitResponse.hasData && bybitResponse.data != null) {
          //print('From WebSocket: ' + bybitResponse.data.toString());
          return Container(child: Text(bybitResponse.data.toString()));
        } else {
          return Container();
        }
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Container(height: 300, color: Colors.blue, child: Example()),
  ));
}
