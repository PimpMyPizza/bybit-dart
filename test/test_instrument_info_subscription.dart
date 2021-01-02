import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToInstrumentInfo() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToInstrumentInfo()', () async {
    bybit.subscribeToInstrumentInfo(symbol: 'BTCUSD');
    var data = await bybit.websocket.stream.first;
    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['topic'] == null) {
      expect(true, false);
      return;
    }
    expect(data['topic'].toString().startsWith('instrument_info'), true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
