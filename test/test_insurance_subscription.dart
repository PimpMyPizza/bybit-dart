import 'test_utils.dart';
import 'package:test/test.dart';
import 'package:bybit/bybit.dart';

void testSubscribeToInsurance() {
  ByBit bybit = ByBit(key: '', password: '');
  setUp(() {
    bybit.connect();
  });

  test('Test ByBit.subscribeToInsurance()', () async {
    bybit.subscribeToInsurance();
    var data = await getFirstValue(bybit.websocket.websocket.stream);
    mustExist([data, data['topic']]);
    expect(data['topic'].toString().startsWith('insurance'), true);
  });

  tearDown(() {
    bybit.disconnect();
  });
}
