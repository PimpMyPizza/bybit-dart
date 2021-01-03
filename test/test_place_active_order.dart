import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testPlaceActiveOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.placeActiveOrder()', () async {
    var data = await bybit.placeActiveOrder(
        symbol: 'BTCUSD',
        side: 'Buy',
        orderType: 'Buy',
        quantity: 10,
        timeInForce: 'what?');

    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['ret_code'] == null) {
      expect(true, false);
      return;
    }
    expect(data['ret_code'], 10003);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
