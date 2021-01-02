import 'package:test/test.dart';
import 'package:bybit/bybit.dart';
import 'test_utils.dart';

void testSubscribeToOrderBook() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToOrderBook()', () async {
    bybit.subscribeToOrderBook(depth: 25, symbol: 'BTCUSD');
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([data, data['topic']]);
    expect(data['topic'], 'orderBookL2_25.BTCUSD');
  });

  tearDown(() {
    bybit.disconnect();
  });
}
