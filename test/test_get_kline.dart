import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetKLine() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getKLine()', () async {
    String dataStr =
        await bybit.getKLine(symbol: 'BTCUSD', interval: 'D', from: 1581231260);
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_msg']]);
    expect(data['ret_msg'].toString() == 'OK', true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
