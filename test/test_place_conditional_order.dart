import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testPlaceConditionalOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.placeConditionalOrder()', () async {
    String dataStr = await bybit.placeConditionalOrder(
        symbol: 'BTCUSD',
        side: 'Buy',
        orderType: 'Buy',
        quantity: '10',
        basePrice: '10',
        triggerPrice: '10',
        timeInForce: '10',
        triggerBy: 'dontcare');
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_code']]);
    expect(data['ret_code'], 10003);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
