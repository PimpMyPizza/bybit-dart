import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetOpenInterest() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getOpenInterest()', () async {
    var data = await bybit.getOpenInterest(symbol: 'BTCUSD', interval: '30min');

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
