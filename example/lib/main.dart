import 'package:bybit/bybit.dart';

/// Read X ([count]) messages from a stream.
Future<void> readWebSocket(Stream<dynamic> stream, int count) async {
  int i = 0;
  await for (var value in stream) {
    print(value);
    i++;
    if (i >= count) return;
  }
}

void main() async {
  ByBit bybit = ByBit(logLevel: 'ERROR');
  bybit.connect();
  bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
  await readWebSocket(bybit.websocket.stream, 3);
  var symbols = await bybit.getSymbolsInfo();
  print(symbols);
  bybit.disconnect();
}
