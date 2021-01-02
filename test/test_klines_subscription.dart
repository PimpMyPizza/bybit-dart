import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToKlines() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToKlines()', () async {
    bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([data, data['success'], data['request']['op']]);
    expect(data['success'], true);
    expect(data['request']['op'], 'subscribe');
  });

  tearDown(() {
    bybit.disconnect();
  });
}
