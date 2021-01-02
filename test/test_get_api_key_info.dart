import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetApiKeyInfo() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getApiKeyInfo()', () async {
    var data = await bybit.getApiKeyInfo();

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
