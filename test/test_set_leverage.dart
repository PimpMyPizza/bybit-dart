import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSetLeverage() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.setLeverage()', () async {
    var data = await bybit.setLeverage(symbol: 'BTCUSD', leverage: 2);

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
