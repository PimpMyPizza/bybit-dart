import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetLiquidatedOrders() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getLiquidatedOrders()', () async {
    var data = await bybit.getLiquidatedOrders(symbol: 'BTCUSD');

    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['ret_code'] == null) {
      expect(true, false);
      return;
    }
    expect(data['ret_code'], 0);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
