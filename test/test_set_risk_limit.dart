import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSetRiskLimit() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.setRiskLimit()', () async {
    var data = await bybit.setRiskLimit(symbol: 'BTCUSD', riskId: 123);

    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['ret_code'] == null) {
      expect(true, false);
      return;
    }
    expect(data['ret_code'], 10009);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
