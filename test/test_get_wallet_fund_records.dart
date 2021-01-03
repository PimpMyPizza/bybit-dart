import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testGetWalletFundRecords() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.getWalletFundRecords()', () async {
    var data = await bybit.getWalletFundRecords();

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
