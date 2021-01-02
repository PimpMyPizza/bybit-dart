import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetPredictedFundingRateAndFundingFee() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getPredictedFundingRateAndFundingFee()', () async {
    var data =
        await bybit.getPredictedFundingRateAndFundingFee(symbol: 'BTCUSD');

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
