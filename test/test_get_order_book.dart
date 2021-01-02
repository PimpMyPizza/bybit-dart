import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetOrderBook() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getOrderBook()', () async {
    var data = await bybit.getOrderBook(symbol: 'BTCUSD');

    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['ret_code'] == null) {
      expect(true, false);
      return;
    }
    expect(data['ret_code'] == 0, true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
