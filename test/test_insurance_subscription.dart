import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToInsurance() {
  var bybit = ByBit();
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToInsurance()', () async {
    bybit.subscribeToInsurance();
    var data = await bybit.websocket.stream.first;
    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['topic'] == null) {
      expect(true, false);
      return;
    }
    expect(data['topic'].toString().startsWith('insurance'), true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
