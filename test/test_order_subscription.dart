import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToOrder()', () async {
    bybit.subscribeToOrder();
    var data = await bybit.websocket.stream.first;
    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['request'] == null) {
      expect(true, false);
      return;
    }
    if (data['request']['op'] == null) {
      expect(true, false);
      return;
    }
    expect(data['request']['op'].toString() == 'subscribe', true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
