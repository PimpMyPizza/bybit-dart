import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testPlaceActiveOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.placeActiveOrder()', () async {
    String dataStr = await bybit.placeActiveOrder(
        symbol: 'BTCUSD',
        side: 'Buy',
        orderType: 'Buy',
        quantity: 10,
        timeInForce: 'what?');
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_code']]);
    expect(data['ret_code'], 10003);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
