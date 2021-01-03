import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetSymbolsInfo() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getSymbolsInfo()', () async {
    var data = await bybit.getSymbolsInfo();

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
