import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

class ExampleByBitREST extends StatefulWidget {
  @override
  _ExampleByBitRESTState createState() => _ExampleByBitRESTState();
}

class _ExampleByBitRESTState extends State<ExampleByBitREST> {
  @override
  Widget build(BuildContext context) {
    ByBit bybit = ByBit.getInstance();
    return FutureBuilder(
      future: bybit.getKLine(symbol: 'BTCUSD', from: 1581231260, interval: 'D'),
      builder: (context, bybitResponse) {
        // Handle the bybit response here
        if (bybitResponse.hasData) {
          print('From REST API: ' + bybitResponse.data.toString());
          return Container(child: Text(bybitResponse.data));
        } else {
          return Container();
        }
      },
    );
  }
}
