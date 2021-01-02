import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetFundingRate() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getFundingRate()', () async {
    String dataStr = await bybit.getFundingRate(symbol: 'BTCUSD');
    Map<String, dynamic> data = asValidJson(dataStr);
    print(data);
    mustExist([data, data['ret_code']]);
    expect(data['ret_code'], 10017);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
