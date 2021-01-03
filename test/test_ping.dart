import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testPing() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.ping()', () async {
    bybit.ping();
    var data = await bybit.websocket.stream.first;
    if (data == null) {
      expect(true, false);
      return;
    }
    if (data['success'] == null) {
      expect(true, false);
      return;
    }
    expect(data['success'], true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
