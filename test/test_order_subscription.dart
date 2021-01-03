import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToOrder() {
  var bybit = ByBit();
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
