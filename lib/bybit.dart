library bybit;

import 'package:bybit/bybit_rest.dart';
import 'package:bybit/bybit_websocket.dart';
import 'package:meta/meta.dart';
import 'package:bybit/logger.dart';
import 'package:logger/logger.dart';

/// That class opens a WebSocket to communicate with the bybit API
/// You can subscribes to several topics over that WebSocket
/// To see a complete list of all endpoints, see
/// https://bybit-exchange.github.io/docs/inverse/#t-websocket
class ByBit {
  /// Used for the websocket connection with bybit.
  ByBitWebSocket websocket;

  /// Used for the REST communication with bybit.
  ByBitRest rest;

  /// For easy debugging
  LoggerSingleton log;

  /// The constructor use default parameters without api-key.
  /// If you want to use all endpoints, you must provite a valid
  /// [key] and [password]. Go to https://www.bybit.com/app/user/api-management
  /// To generate your key. If you're using the websockets, a ping will be
  /// sent every [pingLoopTimer] seconds to the server to maintain connection
  ByBit(
      {String key = '',
      String password = '',
      String restUrl = 'https://api.bybit.com',
      int restTimeout = 3000,
      String websocketUrl = 'wss://stream.bybit.com/realtime',
      int websocketTimeout = 1000,
      int pingLoopTimer = 30,
      String logLevel = 'WARNING'}) {
    if (logLevel == 'ERROR') {
      Logger.level = Level.error;
    } else if (logLevel == 'WARNING') {
      Logger.level = Level.warning;
    } else if (logLevel == 'INFO') {
      Logger.level = Level.info;
    } else if (logLevel == 'DEBUG') {
      Logger.level = Level.debug;
    } else {
      Logger.level = Level.nothing;
    }
    log = LoggerSingleton();
    websocket = ByBitWebSocket(
        key: key,
        password: password,
        timeout: websocketTimeout,
        url: websocketUrl,
        pingLoopTimer: pingLoopTimer);
    rest = ByBitRest(
        key: key, password: password, url: restUrl, timeout: restTimeout);
  }

  /// Connect to the WebSocket server and/or the REST API server
  void connect({bool toWebSocket = true, bool toRestApi = true}) {
    log.i('Connect to Bybit.');
    if (toWebSocket) websocket.connect();
    if (toRestApi) rest.connect();
  }

  /// Disconnect the websocket and http client
  void disconnect() {
    log.i('Disconnect from Bybit.');
    websocket.disconnect();
    rest.disconnect();
  }

  /// Get the orderbook.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook
  Future<dynamic> getOrderBook({@required String symbol}) async {
    log.i('Get order book');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/public/orderBook/L2', type: 'GET', parameters: parameters);
  }

  /// Get kline. https://bybit-exchange.github.io/docs/inverse/?console#t-querykline
  Future<dynamic> getKLine(
      {@required String symbol,
      @required String interval,
      @required int from,
      int limit = -1}) async {
    log.i('Get KLines for symbol ' + symbol);
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['interval'] = interval;
    parameters['from'] = from;
    if (limit > 0) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/public/kline/list', type: 'GET', parameters: parameters);
  }

  /// Get the latest information for symbol.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo
  Future<dynamic> getTickers({String symbol}) {
    log.i('Get tickers');
    var parameters = <String, dynamic>{};
    if (symbol != null) parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/public/tickers', type: 'GET', parameters: parameters);
  }

  /// Get recent trades.
  ///
  /// Returns the last trades from a trade id [from] with a limit of [limit]
  /// trades. If no [from] value is given, the latest [limit] trades will be
  /// returned (default [limit]: 500, max: 1000)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords
  Future<dynamic> getTradingRecords(
      {@required String symbol, int from, int limit}) {
    log.i('Get trading records');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (from != null) parameters['from'] = from;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/public/trading-records',
        type: 'GET',
        parameters: parameters);
  }

  /// Get the information for all symbols.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  Future<dynamic> getSymbolsInfo() {
    log.i('Get symbols information');
    return rest.request(path: '/v2/public/symbols', type: 'GET');
  }

  /// Retrieve the liquidated orders.
  ///
  /// The query range is the last seven days of data. You can pass the [startTime]
  /// and [endTime] timestamps (in milliseconds) or a trade-id ([from]) and/or
  /// a [limit] (max 1000, default 500).
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  Future<dynamic> getLiquidatedOrders(
      {@required String symbol,
      int from,
      int limit,
      int startTime,
      int endTime}) {
    log.i('Get the liquidated orders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (from != null) parameters['from'] = from;
    if (limit != null) parameters['limit'] = limit;
    if (startTime != null) parameters['start_time'] = startTime;
    if (endTime != null) parameters['end_time'] = endTime;
    return rest.request(
        path: '/v2/public/liq-records', type: 'GET', parameters: parameters);
  }

  /// Query mark price kline (like Query Kline but for mark price).
  ///
  /// https://bybit-exchange.github.io/docs/inverse/#t-markpricekline
  Future<dynamic> getMarkPriceKLine(
      {@required String symbol,
      @required String interval,
      @required int from,
      int limit}) {
    log.i('Get the liquidated orders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['interval'] = interval;
    parameters['from'] = from;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/public/mark-price-kline',
        type: 'GET',
        parameters: parameters);
  }

  /// Gets the total amount of unsettled contracts. In other words, the total
  /// number of contracts held in open positions.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<dynamic> getOpenInterest(
      {@required String symbol, @required String interval, int limit}) {
    log.i('Get the liquidated orders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['period'] = interval;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/public/open-interest', type: 'GET', parameters: parameters);
  }

  /// Obtain filled orders worth more than 500,000 USD within the last 24h.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<dynamic> getLatestBigDeals({@required String symbol, int limit}) {
    log.i('Get the liquidated orders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/public/big-deal', type: 'GET', parameters: parameters);
  }

  /// Gets the Bybit user accounts' long-short ratio.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<dynamic> getLongShortRatio(
      {@required String symbol, @required String interval, int limit}) {
    log.i('Get the liquidated orders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['period'] = interval;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/public/account-ratio', type: 'GET', parameters: parameters);
  }

  /// Place active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive
  Future<dynamic> placeActiveOrder(
      {@required String symbol,
      @required String side,
      @required String orderType,
      @required int quantity,
      @required String timeInForce,
      double price,
      double takeProfit,
      double stopLoss,
      bool reduceOnly,
      bool closeOnTrigger,
      String orderLinkId}) {
    log.i('Place an active order');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['side'] = side;
    parameters['order_type'] = orderType;
    parameters['qty'] = quantity;
    parameters['time_in_force'] = timeInForce;
    if (price != null) parameters['price'] = price;
    if (takeProfit != null) parameters['take_profit'] = takeProfit;
    if (stopLoss != null) parameters['stop_loss'] = stopLoss;
    if (reduceOnly != null) parameters['reduce_only'] = reduceOnly;
    if (closeOnTrigger != null) parameters['close_on_trigger'] = closeOnTrigger;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return rest.request(
        path: '/v2/private/order/create',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-getactive
  Future<dynamic> getActiveOrder(
      {@required String symbol,
      String orderStatus,
      String direction,
      int limit,
      String cursor}) async {
    log.i('Get user active order list');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderStatus != null) parameters['order_status'] = orderStatus;
    if (direction != null) parameters['direction'] = direction;
    if (limit != null) parameters['limit'] = limit;
    if (cursor != null) parameters['cursor'] = cursor;
    return rest.request(
        path: '/v2/private/order/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel active order. Note that either orderId or orderLinkId are required
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelactive
  Future<dynamic> cancelActiveOrder(
      {@required String symbol, String orderId, String orderLinkId}) {
    log.i('Cancel active order');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return rest.request(
        path: '/v2/private/order/cancel',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel all active orders that are unfilled or partially filled. Fully
  /// filled orders cannot be cancelled.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallactive
  Future<dynamic> cancelAllActiveOrders({@required String symbol}) {
    log.i('Cancel all active orders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/order/cancelAll',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Replace order can modify/amend your active orders.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replaceactive
  Future<dynamic> updateActiveOrder(
      {@required String symbol,
      String orderId,
      String orderLinkId,
      double newOrderQuantity,
      double newOrderPrice}) {
    log.i('Replace active order');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    if (newOrderQuantity != null) {
      parameters['p_r_qty'] = newOrderQuantity.toString();
    }
    if (newOrderPrice != null) {
      parameters['p_r_price'] = newOrderPrice.toString();
    }
    return rest.request(
        path: '/v2/private/order/replace',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Query real-time active order information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-queryactive
  Future<dynamic> getRealTimeActiveOrder(
      {@required String symbol, String orderId, String orderLinkId}) {
    log.i('Query real-time active order information');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return rest.request(
        path: '/v2/private/order',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Place a market price conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-placecond
  Future<dynamic> placeConditionalOrder(
      {@required String symbol,
      @required String side,
      @required String orderType,
      @required int quantity,
      double price,
      @required double basePrice,
      @required double triggerPrice,
      @required String timeInForce,
      @required String triggerBy,
      bool closeOnTrigger,
      String orderLinkId}) {
    log.i('Place conditional Order');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['side'] = side;
    parameters['order_type'] = orderType;
    parameters['qty'] = quantity.toString();
    parameters['base_price'] = basePrice.toString();
    parameters['stop_px'] = triggerPrice.toString();
    parameters['time_in_force'] = timeInForce;
    parameters['trigger_by'] = triggerBy;
    if (price != null) parameters['price'] = price.toString();
    if (closeOnTrigger != null) parameters['close_on_trigger'] = closeOnTrigger;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return rest.request(
        path: '/v2/private/stop-order/create',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user conditional order list.
  /// https://bybit-exchange.github.io/docs/inverse/#t-getcond
  Future<dynamic> getConditionalOrders(
      {@required String symbol,
      String stopOrderStatus,
      String direction,
      int limit,
      String cursor}) {
    log.i('Get user conditional order list.');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (stopOrderStatus != null) {
      parameters['stop_order_status'] = stopOrderStatus;
    }
    if (direction != null) parameters['direction'] = direction;
    if (limit != null) parameters['limit'] = limit;
    if (cursor != null) parameters['cursor'] = cursor;
    return rest.request(
        path: '/v2/private/stop-order/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel untriggered conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelcond
  Future<dynamic> cancelConditionalOrder(
      {@required String symbol, String orderId, String orderLinkId}) {
    log.i('Cancel conditional order');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return rest.request(
        path: '/v2/private/stop-order/cancel',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel all untriggered conditional orders
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallcond
  Future<dynamic> cancelAllConditionalOrders({@required String symbol}) {
    log.i('Cancel all conditional orders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/stop-order/cancelAll',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Update conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-replacecond
  Future<dynamic> updateConditionalOrder(
      {@required String symbol,
      String stopOrderId,
      String orderLinkId,
      int newOrderQuantity,
      double newOrderPrice,
      double newTriggerPrice}) {
    log.i('Update conditional order');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (stopOrderId != null) parameters['stop_order_id'] = stopOrderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    if (newOrderQuantity != null) {
      parameters['p_r_qty'] = newOrderQuantity.toString();
    }
    if (newOrderPrice != null) {
      parameters['p_r_price'] = newOrderPrice.toString();
    }
    if (newTriggerPrice != null) {
      parameters['p_r_trigger_price'] = newTriggerPrice.toString();
    }
    return rest.request(
        path: '/v2/private/stop-order/replace',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Query conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-querycond
  Future<dynamic> getConditionalOrder(
      {@required String symbol, String stopOrderId, String orderLinkId}) {
    log.i('Query conditional order');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (stopOrderId != null) parameters['stop_order_id'] = stopOrderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return rest.request(
        path: '/v2/private/stop-order',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user position list
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-myposition
  Future<dynamic> getPosition({String symbol}) async {
    log.i('Get user position list.');
    var parameters = <String, dynamic>{};
    if (symbol != null) parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/position/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Update margin
  /// https://bybit-exchange.github.io/docs/inverse/#t-changemargin
  Future<dynamic> setMargin(
      {@required String symbol, @required double margin}) {
    log.i('Update margin');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['margin'] = margin.toString();
    return rest.request(
        path: '/v2/private/position/change-position-margin',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Set trading-stop
  /// https://bybit-exchange.github.io/docs/inverse/#t-tradingstop
  Future<dynamic> setTradingStop(
      {@required String symbol,
      double takeProfit,
      double stopLoss,
      double trailingStop,
      String tpTriggerBy,
      String slTriggerBy,
      double newTrailingTriggerPrice}) {
    log.i('Set trading stop.');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (takeProfit != null) parameters['take_profit'] = takeProfit;
    if (stopLoss != null) parameters['stop_loss'] = stopLoss;
    if (trailingStop != null) parameters['trailing_stop'] = trailingStop;
    if (tpTriggerBy != null) parameters['tp_trigger_by'] = tpTriggerBy;
    if (slTriggerBy != null) parameters['sl_trigger_by'] = slTriggerBy;
    if (newTrailingTriggerPrice != null) {
      parameters['new_trailing_active'] = newTrailingTriggerPrice;
    }
    return rest.request(
        path: '/v2/private/position/trading-stop',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Set leverage
  /// https://bybit-exchange.github.io/docs/inverse/#t-setleverage
  Future<dynamic> setLeverage(
      {@required String symbol, @required double leverage}) {
    log.i('Set leverage.');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['leverage'] = leverage;
    return rest.request(
        path: '/v2/private/position/leverage/save',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user's trading records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-usertraderecords
  Future<dynamic> getUserTradingRecords(
      {@required String symbol,
      String orderId,
      int startTime,
      int page,
      int limit,
      String order}) {
    log.i('Get user trading records.');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (startTime != null) parameters['start_time'] = startTime;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    if (order != null) parameters['order'] = order;
    return rest.request(
        path: '/v2/private/execution/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user's closed profit and loss records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-closedprofitandloss
  Future<dynamic> getUserClosedProfit(
      {@required String symbol,
      int startTime,
      int endTime,
      String execType,
      int page,
      int limit}) {
    log.i('Get user closed profit (PNL)');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (startTime != null) parameters['start_time'] = startTime;
    if (endTime != null) parameters['end_time'] = endTime;
    if (execType != null) parameters['exec_type'] = execType;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/private/trade/closed-pnl/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get risk limit
  /// https://bybit-exchange.github.io/docs/inverse/#t-risklimit
  Future<dynamic> getRiskLimit() {
    log.i('Get risk limit.');
    return rest.request(
        path: '/open-api/wallet/risk-limit/list',
        type: 'GET',
        withAuthentication: true);
  }

  /// Set risk limit
  /// https://bybit-exchange.github.io/docs/inverse/#t-setrisklimit
  Future<dynamic> setRiskLimit(
      {@required String symbol, @required int riskId}) {
    log.i('Set risk limit');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['risk_id'] = riskId;
    return rest.request(
        path: '/open-api/wallet/risk-limit',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get the last funding rate
  /// https://bybit-exchange.github.io/docs/inverse/#t-fundingrate
  Future<dynamic> getFundingRate({@required String symbol}) {
    log.i('Get funding rate');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/funding/prev-funding-rate',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get previous funding fee
  /// https://bybit-exchange.github.io/docs/inverse/#t-mylastfundingfee
  Future<dynamic> getPreviousFundingFee({@required String symbol}) {
    log.i('Get previous funding fee.');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/funding/prev-funding',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get predicted funding rate and my funding fee.
  /// https://bybit-exchange.github.io/docs/inverse/#t-predictedfunding
  Future<dynamic> getPredictedFundingRateAndFundingFee(
      {@required String symbol}) {
    log.i('Get predicted funding rate and funding fee.');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/funding/predicted-funding',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user's API key information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-key
  Future<dynamic> getApiKeyInfo() {
    log.i('Get user API key information.');
    return rest.request(
        path: '/v2/private/account/api-key',
        type: 'GET',
        withAuthentication: true);
  }

  /// Get user's LCP (data refreshes once an hour).
  /// https://bybit-exchange.github.io/docs/inverse/#t-lcp
  Future<dynamic> getUserLCP({@required String symbol}) {
    log.i('Get user LCP');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/account/lcp',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get wallet balance
  /// https://bybit-exchange.github.io/docs/inverse/#t-wallet
  Future<dynamic> getWalletBalance({@required String currency}) {
    log.i('Get wallet balance information.');
    var parameters = <String, dynamic>{};
    parameters['coin'] = currency;
    return rest.request(
        path: '/v2/private/wallet/balance',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get wallet fund records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-walletrecords
  Future<dynamic> getWalletFundRecords(
      {String currency,
      int startTimestamp,
      int endTimestamp,
      String walletFundType,
      int page,
      int limit}) {
    log.i('Get wallet fund records.');
    var parameters = <String, dynamic>{};
    if (currency != null) parameters['currency'] = currency;
    if (currency != null) parameters['coin'] = currency;
    if (startTimestamp != null) {
      parameters['start_date'] = startTimestamp.toString();
    }
    if (endTimestamp != null) parameters['end_date'] = endTimestamp.toString();
    if (walletFundType != null) parameters['wallet_fund_type'] = walletFundType;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/private/wallet/fund/records',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get withdrawal records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-withdrawrecords
  Future<dynamic> getWithdrawalRecords(
      {String currency,
      int startTimestamp,
      int endTimestamp,
      String status,
      int page,
      int limit}) {
    log.i('Get withdrawal records.');
    var parameters = <String, dynamic>{};
    if (currency != null) parameters['coin'] = currency;
    if (startTimestamp != null) {
      parameters['start_date'] = startTimestamp.toString();
    }
    if (endTimestamp != null) parameters['end_date'] = endTimestamp.toString();
    if (status != null) parameters['status'] = status;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/private/wallet/withdraw/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get asset exchange records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-assetexchangerecords
  Future<dynamic> getAssetExchangeRecords(
      {String direction, int from, int limit}) {
    log.i('Get asset exchange records.');
    var parameters = <String, dynamic>{};
    if (from != null) parameters['from'] = from;
    if (direction != null) parameters['direction'] = direction;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(
        path: '/v2/private/exchange-order/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get the server time (used for synchronization purposes for example)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-servertime
  Future<dynamic> getServerTime() async {
    log.i('Get server time');
    return rest.request(path: '/v2/public/time', type: 'GET');
  }

  /// Get Bybit OpenAPI announcements in the last 30 days in reverse order.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-announcement
  Future<dynamic> getAnnouncement() async {
    log.i('Get annoucements');
    return rest.request(path: '/v2/public/announcement', type: 'GET');
  }

  /// Send ping to the WebSocket server
  void ping() {
    log.i('Send ping');
    websocket.ping();
  }

  /// Subscribe to the KLines channel. A list of valid [interval] values string
  /// is at: https://bybit-exchange.github.io/docs/inverse/#t-websocketklinev2
  void subscribeToKlines({@required String symbol, @required String interval}) {
    log.i('Subscribe to KLines with symbol: ' +
        symbol +
        ' and interval: ' +
        interval);
    websocket.subscribeTo(topic: 'klineV2', symbol: symbol, filter: interval);
  }

  /// Fetches the orderbook with a [depth] of '25' or '200' orders per side.
  /// is at: https://bybit-exchange.github.io/docs/inverse/#t-websocketorderbook25
  void subscribeToOrderBook({@required int depth, String symbol = ''}) {
    log.i('Subscribe to orderbook with depth : ' +
        depth.toString() +
        ' for the symbol: ' +
        symbol);
    if (depth == 25) {
      websocket.subscribeTo(
          topic: 'orderBookL2_' + depth.toString(), symbol: symbol);
    } else if (depth == 200) {
      websocket.subscribeTo(
          topic: 'orderBook_' + depth.toString() + '.100ms', symbol: symbol);
    }
  }

  /// Get real-time trading information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websockettrade
  void subscribeToTrades({String symbol = ''}) {
    log.i('Subscribe to trades.');
    websocket.subscribeTo(topic: 'trade', symbol: symbol);
  }

  /// Get the daily insurance fund update.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketinsurance
  void subscribeToInsurance({String currency = ''}) {
    log.i('Subscribe to insurance.');
    websocket.subscribeTo(topic: 'insurance', symbol: currency);
  }

  /// Get latest information for symbol.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketinstrumentinfo
  void subscribeToInstrumentInfo({@required String symbol}) {
    log.i('Subscribe to the latest symbol information.');
    websocket.subscribeTo(topic: 'instrument_info.100ms', symbol: symbol);
  }

  /// Subscribe to the position channel. You need to have a valid api-key
  /// in order to receive a valid response from the server
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketposition
  void subscribeToPosition() {
    log.i('Subscribe to position');
    websocket.subscribeTo(topic: 'position');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketexecution
  void subscribeToExecution() {
    log.i('Subscribe to execution');
    websocket.subscribeTo(topic: 'execution');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketorder
  void subscribeToOrder() {
    log.i('Subscribe to order');
    websocket.subscribeTo(topic: 'order');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketstoporder
  void subscribeToStopOrder() {
    log.i('Subscribe to stop_order');
    websocket.subscribeTo(topic: 'stop_order');
  }
}
