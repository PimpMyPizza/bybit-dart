import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSetRiskLimit() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.setRiskLimit()', () async {
    String dataStr = await bybit.setRiskLimit(symbol: 'BTCUSD', riskId: 123);
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_code']]);
    print(data);
    expect(data['ret_code'], 10009);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
