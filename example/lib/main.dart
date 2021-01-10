import 'package:bybit/bybit.dart';

/// Read X ([count]) messages from a stream.
Future<void> readWebSocket(Stream<dynamic> stream, int count) async {
  var i = 0;
  await for (var value in stream) {
    print(value);
    i++;
    if (i >= count) return;
  }
}

void main() async {
  var bybit = ByBit(logLevel: 'DEBUG');
  bybit.getSymbolsInfoPeriodic(period: Duration(seconds: 1));
  bybit.connect();
  //bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
  await readWebSocket(bybit.stream, 30);
  //var symbols = await bybit.getSymbolsInfo();
  //print(symbols);
  var test = await bybit.getLiquidatedOrders(symbol: 'ETHUSD', limit: 3);
  print(test);
  bybit.disconnect();
}
