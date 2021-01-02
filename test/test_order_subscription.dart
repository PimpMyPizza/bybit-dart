import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToOrder()', () async {
    bybit.subscribeToOrder();
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([data, data['request'], data['request']['op']]);
    expect(data['request']['op'].toString() == 'subscribe', true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
