import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

/// Just a container that shows the return value from a REST call to bybit
class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var bybit = ByBit();
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

void main() {
  runApp(MaterialApp(
    home: Container(height: 300, color: Colors.green, child: Example()),
  ));
}
