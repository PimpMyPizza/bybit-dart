import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetLatestBigDeals() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getLatestBigDeals()', () async {
    var data = await bybit.getLatestBigDeals(symbol: 'BTCUSD');

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
