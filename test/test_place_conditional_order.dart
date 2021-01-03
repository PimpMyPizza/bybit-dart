import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testPlaceConditionalOrder() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.placeConditionalOrder()', () async {
    var data = await bybit.placeConditionalOrder(
        symbol: 'BTCUSD',
        side: 'Buy',
        orderType: 'Buy',
        quantity: '10',
        basePrice: '10',
        triggerPrice: '10',
        timeInForce: '10',
        triggerBy: 'dontcare');

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
