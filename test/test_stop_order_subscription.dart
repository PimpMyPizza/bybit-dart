import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToStopOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToStopOrder()', () async {
    bybit.subscribeToStopOrder();
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([data, data['request'], data['request']['op']]);
    expect(data['request']['op'].toString() == 'subscribe', true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
