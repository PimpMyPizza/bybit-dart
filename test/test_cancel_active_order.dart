import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testCancelActiveOrder() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.cancelActiveOrder()', () async {
    String dataStr = await bybit.cancelActiveOrder(symbol: 'BTCUSD');
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_code']]);
    expect(data['ret_code'] == 10003, true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
