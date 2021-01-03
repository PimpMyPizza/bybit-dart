import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToOrderBook() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToOrderBook()', () async {
    bybit.subscribeToOrderBook(depth: 25, symbol: 'BTCUSD');
    var data = await bybit.websocket.stream.first;
    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['topic'] == null) {
      expect(true, false);
      return;
    }
    expect(data['topic'], 'orderBookL2_25.BTCUSD');
  });

  tearDown(() {
    bybit.disconnect();
  });
}
