import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testUpdateConditionalOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.updateConditionalOrder()', () async {
    String dataStr = await bybit.updateConditionalOrder(symbol: 'BTCUSD');
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_code']]);
    expect(data['ret_code'], 10003);
  });

  tearDown(() {
    bybit.disconnect();
  });
}