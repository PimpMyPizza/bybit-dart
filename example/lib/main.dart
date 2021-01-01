import 'package:example/example_bybit_rest.dart';
import 'package:example/example_bybit_websocket.dart';
import 'package:flutter/material.dart';
import 'package:bybit/bybit.dart';

class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  @override
  Widget build(BuildContext context) {
    ByBit bybit = ByBit.getInstance(
        key: "8YycMEZZOWOD13k3Bx",
        password: "9qgfKOqOVBhRmMpED8jACxBMbtEHgJNKJw2M",
        logLevel: 'INFO',
        restUrl: 'https://api.bybit.com',
        restTimeout: 3000,
        websocketUrl: 'wss://stream.bytick.com/realtime',
        websocketTimeout: 2000);
    bybit.connect();
    return MaterialApp(
        home: Column(children: <Widget>[
      Container(height: 300, color: Colors.blue, child: ExampleByBitWebSocket()),
      Container(height: 300, color: Colors.green, child: ExampleByBitREST())
    ]));
  }
}

void main() {
  runApp(Example());
}
