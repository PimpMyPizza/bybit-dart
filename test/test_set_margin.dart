import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSetMargin() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.setMargin()', () async {
    var data = await bybit.setMargin(symbol: 'BTCUSD', margin: 10);

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
