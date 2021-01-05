import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetMarkPriceKLine() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getMarkPriceKLine()', () async {
    var data = await bybit.getMarkPriceKLine(
        symbol: 'BTCUSD', interval: '1', from: 1581231260, limit: 2);

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
