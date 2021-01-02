import 'package:test/test.dart';
import 'package:bybit/bybit.dart';
import 'test_utils.dart';

void testsubscribeToTrades() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToTrades()', () async {
    bybit.subscribeToTrades();
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([
      data,
      data['success'],
      data['request']['op'],
      data['request']['args']
    ]);
    expect(data['success'], true);
    expect(data['request']['op'], 'subscribe');
    expect(data['request']['args'], ['trade']);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
