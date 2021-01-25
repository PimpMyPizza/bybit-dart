/// State class to remember the user config. This class is
/// used when we have a brocken socket and want to make an
/// auto reconnect and keep the user settings
class ByBitState {
  var ws = ByBitWebSocketState();
}

class ByBitWebSocketState {
  bool isSubscribedToStopOrder = false;
  bool isSubscribedToOrderBook = false;
  var paramOrderBook = <ByBitWebSocketOrderBookParameters>[];
  bool isSubscribedToExecution = false;
  bool isSubscribedToPosition = false;
  bool isSubscribedToInstrumentInfo = false;
  var paramInstrumentInfo = <ByBitWebSocketInstrumentInfoParameters>[];
  bool isSubscribedToInsurance = false;
  var paramInsurance = <ByBitWebSocketInsuranceParameters>[];
  bool isSubscribedToTrades = false;
  var paramTrades = <ByBitWebSocketTradesParameters>[];
  bool isSubscribedToKlines = false;
  var paramKlines = <ByBitWebSocketKlinesParameters>[];
  bool isSubscribedToOrder = false;
}

class ByBitWebSocketKlinesParameters {
  String symbol;
  String interval;
  ByBitWebSocketKlinesParameters({this.symbol, this.interval});
}

class ByBitWebSocketTradesParameters {
  String symbol;
  ByBitWebSocketTradesParameters({this.symbol});
}

class ByBitWebSocketInsuranceParameters {
  String currency;
  ByBitWebSocketInsuranceParameters({this.currency});
}

class ByBitWebSocketInstrumentInfoParameters {
  String symbol;
  ByBitWebSocketInstrumentInfoParameters({this.symbol});
}

class ByBitWebSocketOrderBookParameters {
  int depth;
  String symbol;
  ByBitWebSocketOrderBookParameters({this.depth, this.symbol});
}
