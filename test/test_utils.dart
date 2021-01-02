import 'dart:convert';
import 'package:test/test.dart';

Map<String, dynamic> asValidJson(dynamic data) {
  Map<String, dynamic> json = jsonDecode(data);
  return json;
}

Future<Map<String, dynamic>> getFirstValue(Stream<dynamic> stream) async {
  var firstVal = await stream.first;
  return await asValidJson(firstVal);
}

void mustExist([dynamic values]) {
  for (var val in values) {
    expect(val != null, true);
  }
}
