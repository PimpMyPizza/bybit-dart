import 'package:bybit/bybit.dart';

/// Read X ([count]) messages from a stream.
Future<void> readWebSocket(Stream<dynamic> stream, int count) async {
  var i = 0;
  await for (var value in stream) {
    i++;
    print(value);
    if (i >= count) return;
  }
}

void main() async {
  var bybit = ByBit(logLevel: 'INFO');
  // Connect to the Server
  bybit.connect();

  // Define REST API calls that we want to make periodically
  bybit.getServerTimePeriodic(period: Duration(seconds: 5));
  bybit.getAnnouncementPeriodic(period: Duration(seconds: 5));
  bybit.getOpenInterestPeriodic(
      symbol: 'ETHUSD',
      interval: '15min',
      period: Duration(seconds: 2),
      limit: 3);

  // Subscribe to WebSockets channels
  bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');

  // Show the stream output
  await readWebSocket(bybit.stream, 10);

  // Once the 10 first server response are shown, make a single REST API call
  var symbols = await bybit.getSymbolsInfo();
  print(symbols);

  // Close sockets
  bybit.disconnect();
}
