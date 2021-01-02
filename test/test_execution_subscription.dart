import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToExecution() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToExecution()', () async {
    bybit.subscribeToExecution();
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([data, data['request'], data['request']['op']]);
    expect(data['request']['op'].toString() == 'subscribe', true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
