import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetConditionalOrder() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getConditionalOrder()', () async {
    var data = await bybit.getConditionalOrder(symbol: 'BTCUSD');

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
