import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testPing() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.ping()', () async {
    bybit.ping();
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([
      data,
      data['success'],
      data['ret_msg'],
      data['request']['op'],
    ]);
    expect(data['success'], true);
    expect(data['ret_msg'], 'pong');
    expect(data['request']['op'], 'ping');
  });

  tearDown(() {
    bybit.disconnect();
  });
}
