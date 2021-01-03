import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToKlines() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToKlines()', () async {
    bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
    var data = await bybit.websocket.stream.first;
    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['success'] == null) {
      expect(true, false);
      return;
    }
    expect(data['success'], true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
