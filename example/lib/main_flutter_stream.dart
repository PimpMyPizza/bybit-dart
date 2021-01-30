import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

/// Just a container that shows the outputs of the ByBit stream
class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var bybit = ByBit(websocketUrl: 'wss://stream.bytick.com/realtime');
    bybit.connect();
    bybit.getServerTimePeriodic(period: Duration(seconds: 5));
    bybit.getAnnouncementPeriodic(period: Duration(seconds: 5));
    bybit.getOpenInterestPeriodic(
        symbol: 'ETHUSD',
        interval: '15min',
        period: Duration(seconds: 2),
        limit: 3);
    bybit.subscribeToKlines(symbol: 'ETHUSD', interval: '1');
    bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
    bybit.subscribeToOrderBook(depth: 25);
    return StreamBuilder(
      stream: bybit.stream,
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
