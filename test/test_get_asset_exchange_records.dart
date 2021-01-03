import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetAssetExchangeRecords() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getAssetExchangeRecords()', () async {
    var data = await bybit.getAssetExchangeRecords();

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
