import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

class MainView extends StatefulWidget {
  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  Widget build(BuildContext context) {
    ByBit bybit = ByBit(apiKey: '', secret: '');
    bybit.connect();
    bybit.subscribeToKlines(symbol: 'ETHUSD', interval: '1');
    bybit.subscribeToKlines(symbol: 'ETHUSD', interval: 'D');
    //bybit.subscribeToPosition(); // with key authentication
    return MaterialApp(
      home: StreamBuilder(
          stream: bybit.websocket.stream,
          builder: (context, bybitResponse) {
            // Handle the bybit response here
            if (bybitResponse.hasData) {
              print(bybitResponse.data);
              return Container(child: Text(bybitResponse.data));
            } else {
              return Container();
            }
          }),
    );
  }
}

void main() {
  runApp(MainView());
}
