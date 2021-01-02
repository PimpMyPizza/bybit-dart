import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetKLine() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getKLine()', () async {
    var data =
        await bybit.getKLine(symbol: 'BTCUSD', interval: 'D', from: 1581231260);

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
