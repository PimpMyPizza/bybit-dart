import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetFundingRate() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getFundingRate()', () async {
    var data = await bybit.getFundingRate(symbol: 'BTCUSD');

    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['ret_code'] == null) {
      expect(true, false);
      return;
    }
    expect(data['ret_code'], 10017);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
