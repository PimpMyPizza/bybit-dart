import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

class ExampleByBitWebSocket extends StatelessWidget {
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
          //print('From WebSocket: ' + bybitResponse.data.toString());
          return Container(child: Text(bybitResponse.data.toString()));
        } else {
          return Container();
        }
      },
    );
  }
}

class ExampleByBitREST extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ByBit bybit = ByBit.getInstance();
    return FutureBuilder(
      //future: bybit.getKLine(symbol: 'BTCUSD', from: 1581231260, interval: 'D'),
      future: bybit.getTickers(),
      builder: (context, bybitResponse) {
        // Handle the bybit response here
        if (bybitResponse.hasData) {
          //print('From REST API: ' + bybitResponse.data.toString());
          return Container(child: Text(bybitResponse.data.toString()));
        } else {
          return Container();
        }
      },
    );
  }
}

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Add a valid key and password if you want to use private topics
    ByBit bybit = ByBit.getInstance(
        logLevel: 'INFO',
        restUrl: 'https://api.bybit.com',
        restTimeout: 3000,
        websocketUrl: 'wss://stream.bytick.com/realtime',
        websocketTimeout: 2000);
    bybit.connect();
    return MaterialApp(
        home: Column(children: <Widget>[
      Container(
          height: 300, color: Colors.blue, child: ExampleByBitWebSocket()),
      Container(height: 300, color: Colors.green, child: ExampleByBitREST())
    ]));
  }
}

void main() {
  runApp(Example());
}
