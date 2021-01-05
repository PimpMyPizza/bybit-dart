import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetLongShortRatio() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getLongShortRatio()', () async {
    var data = await bybit.getLongShortRatio(symbol: 'BTCUSD', interval: '1h');

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
