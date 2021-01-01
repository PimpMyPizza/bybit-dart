
# ByBit

ByBit is a [Dart](https://dart.dev/) package for a communication with the [bybit](https://www.bybit.com/) exchange platform [API](https://bybit-exchange.github.io/docs/inverse/#t-introduction)

* [getInstance](#getInstance)
* [connect](#connect)
* [disconnect](#disconnect)
* [getOrderBook](#getOrderBook)
* [getKLine](#getKLine)
* [getTickers](#getTickers)
* [getTradingRecords](#getTradingRecords)
* [getSymbolsInfo](#getSymbolsInfo)
* [getLiquidatedOrders](#getLiquidatedOrders)
* [placeActiveOrder](#placeActiveOrder)
* [getActiveOrder](#getActiveOrder)
* [cancelActiveOrder](#cancelActiveOrder)
* [cancelAllActiveOrders](#cancelAllActiveOrders)
* [replaceActiveOrder](#replaceActiveOrder)
* [getRealTimeActiveOrder](#getRealTimeActiveOrder)
* [placeConditionalOrder](#placeConditionalOrder)
* [getConditionalOrders](#getConditionalOrders)
* [cancelConditionalOrder](#cancelConditionalOrder)
* [cancelAllConditionalOrders](#cancelAllConditionalOrders)
* [replaceConditionalOrder](#replaceConditionalOrder)
* [getConditionalOrder](#getConditionalOrder)
* [getPosition](#getPosition)
* [updateMargin](#updateMargin)
* [setTradingStop](#setTradingStop)
* [setLeverage](#setLeverage)
* [getUserTradingRecords](#getUserTradingRecords)
* [getUserClosedProfit](#getUserClosedProfit)
* [getRiskLimit](#getRiskLimit)
* [setRiskLimit](#setRiskLimit)
* [getFundingRate](#getFundingRate)
* [getPreviousFundingFee](#getPreviousFundingFee)
* [getPredictedFundingRateAndFundingFee](#getPredictedFundingRateAndFundingFee)
* [getApiKeyInfo](#getApiKeyInfo)
* [getUserLCP](#getUserLCP)
* [getWalletBalance](#getWalletBalance)
* [getWalletFundRecords](#getWalletFundRecords)
* [getWithdrawalRecords](#getWithdrawalRecords)
* [getAssetExchangeRecords](#getAssetExchangeRecords)
* [getServerTime](#getServerTime)
* [getAnnouncement](#getAnnouncement)
* [ping](#ping)
* [subscribeToKlines](#subscribeToKlines)
* [subscribeToOrderBook](#subscribeToOrderBook)
* [subscribeToTrades](#subscribeToTrades)
* [subscribeToInsurance](#subscribeToInsurance)
* [subscribeToInstrumentInfo](#subscribeToInstrumentInfo)
* [subscribeToPosition](#subscribeToPosition)
* [subscribeToExecution](#subscribeToExecution)
* [subscribeToOrder](#subscribeToOrder)
* [subscribeToStopOrder](#subscribeToStopOrder)

----------------------------------------------------------------------------------


### getInstance

  

### connect

  

Connect to the WebSocket server and/or the REST API server

  

### disconnect

  

Disconnect the websocket and http client

  

### getOrderBook

  

Get the orderbook.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook)

  

### getKLine

Get kline. [official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-querykline)

  

### getTickers

Get the latest information for symbol.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo)

### getTradingRecords

Get recent trades.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords)

### getSymbolsInfo

Get symbol info.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol)

  

### getLiquidatedOrders

Retrieve the liquidated orders, The query range is the last seven days of data.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol)

  

### placeActiveOrder

Place active order

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive)

  

### getActiveOrder

Get active order

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive)

  

### cancelActiveOrder

Cancel active order. Note that either orderId or orderLinkId are required

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelactive)

### cancelAllActiveOrders

Cancel all active orders that are unfilled or partially filled. Fully filled orders cannot

be cancelled.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelallactive)

### replaceActiveOrder

Replace order can modify/amend your active orders.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-replaceactive)

  

### getRealTimeActiveOrder

Query real-time active order information.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-queryactive)

### placeConditionalOrder

Place a market price conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-placecond)

  

### getConditionalOrders

Get user conditional order list.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-getcond)

### cancelConditionalOrder

Cancel untriggered conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelcond)

  

### cancelAllConditionalOrders

Cancel all untriggered conditional orders

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelallcond)

  

### replaceConditionalOrder

Replace conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-replacecond)

  

### getConditionalOrder

Query conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-querycond)

### getPosition

Get user position list

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-myposition)

### updateMargin

Update margin

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-changemargin)

  

### setTradingStop

Set trading-stop

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-tradingstop)

### setLeverage

Set leverage

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-setleverage)

  

### getUserTradingRecords

Get user's trading records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-usertraderecords)

### getUserClosedProfit

Get user's closed profit and loss records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-closedprofitandloss)

### getRiskLimit

Get risk limit

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-risklimit)

  

### setRiskLimit

Set risk limit

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-setrisklimit)

  

### getFundingRate

Get the last funding rate

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-fundingrate)

### getPreviousFundingFee

Get previous funding fee

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-mylastfundingfee)

### getPredictedFundingRateAndFundingFee

Get predicted funding rate and my funding fee.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-predictedfunding)

### getApiKeyInfo

Get user's API key information.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-key)

### getUserLCP

Get user's LCP (data refreshes once an hour).

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-lcp)

### getWalletBalance

Get wallet balance

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-wallet)

### getWalletFundRecords

Get wallet fund records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-walletrecords)

### getWithdrawalRecords

Get withdrawal records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-withdrawrecords)

### getAssetExchangeRecords

Get asset exchange records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-assetexchangerecords)

### getServerTime

Get the server time (used for synchronization purposes for example)

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-servertime)


### getAnnouncement

Get Bybit OpenAPI announcements in the last 30 days in reverse order.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-announcement)


### ping

Send ping to the WebSocket server

  

### subscribeToKlines

Subscribe to the KLines channel. A list of valid [interval] values string

is at: [official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketklinev2)

  

### subscribeToOrderBook

Fetches the orderbook with a [depth] of '25' or '200' orders per side.

is at: [official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketorderbook25)

  

### subscribeToTrades

Get real-time trading information.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websockettrade)

  

### subscribeToInsurance

Get the daily insurance fund update.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketinsurance)

  

### subscribeToInstrumentInfo

Get latest information for symbol.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketinstrumentinfo)

  

### subscribeToPosition

Subscribe to the position channel. You need to have a valid api-key in order to receive a valid response from the server

  

### subscribeToExecution

Private topic to subscribe to with a valid api-Key. See

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketexecution)

  

### subscribeToOrder

Private topic to subscribe to with a valid api-Key. See

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketorder)

  

### subscribeToStopOrder

Private topic to subscribe to with a valid api-Key. See

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketstoporder)
