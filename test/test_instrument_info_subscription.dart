import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToInstrumentInfo() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToInstrumentInfo()', () async {
    bybit.subscribeToInstrumentInfo(symbol: 'BTCUSD');
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([data, data['topic']]);
    expect(data['topic'].toString().startsWith('instrument_info'), true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
