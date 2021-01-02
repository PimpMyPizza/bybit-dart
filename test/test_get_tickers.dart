import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetTickers() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getTickers()', () async {
    String dataStr = await bybit.getTickers();
    Map<String, dynamic> data = asValidJson(dataStr);
    mustExist([data, data['ret_msg']]);
    expect(data['ret_msg'].toString() == 'OK', true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
