import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testCancelAllConditionalOrders() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.cancelAllConditionalOrders()', () async {
    String dataStr = await bybit.cancelAllConditionalOrders(symbol: 'BTCUSD');
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_code']]);
    expect(data['ret_code'], 10003);
  });

  tearDown(() {
    bybit.disconnect();
  });
}