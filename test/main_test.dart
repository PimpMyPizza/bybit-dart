import 'test_get_kline.dart';
import 'test_get_order_book.dart';
import 'test_get_tickers.dart';
import 'test_get_trading_records.dart';
import 'test_get_symbol_info.dart';
import 'test_get_liquidated_orders.dart';
import 'test_get_mark_price_kline.dart';
import 'test_get_open_interest.dart';
import 'test_get_latest_big_deals.dart';
import 'test_get_long_short_ration.dart';
import 'test_place_active_order.dart';
import 'test_get_active_order.dart';
import 'test_cancel_active_order.dart';
import 'test_cancel_all_active_orders.dart';
import 'test_update_active_order.dart';
import 'test_get_real_time_active_order.dart';
import 'test_place_conditional_order.dart';
import 'test_get_conditional_orders.dart';
import 'test_cancel_conditional_order.dart';
import 'test_cancel_all_conditional_orders.dart';
import 'test_update_conditional_order.dart';
import 'test_get_conditional_order.dart';
import 'test_get_position.dart';
import 'test_set_margin.dart';
import 'test_set_trading_stop.dart';
import 'test_set_leverage.dart';
import 'test_get_user_trading_records.dart';
import 'test_get_user_closed_profit.dart';
import 'test_get_risk_limit.dart';
import 'test_set_risk_limit.dart';
import 'test_get_funding_rate.dart';
import 'test_get_previous_funding_fee.dart';
import 'test_get_predicted_funding_rate_and_funding_fee.dart';
import 'test_get_api_key_info.dart';
import 'test_get_user_lcp.dart';
import 'test_get_wallet_balance.dart';
import 'test_get_wallet_fund_records.dart';
import 'test_get_withdrawal_records.dart';
import 'test_get_asset_exchange_records.dart';
import 'test_get_server_time.dart';
import 'test_get_announcement.dart';

void main() {
  // REST API calls
  testGetOrderBook();
  testGetKLine();
  testGetTickers();
  testGetTradingRecords();
  testGetSymbolsInfo();
  testGetLiquidatedOrders();
  testGetMarkPriceKLine();
  testGetOpenInterest();
  testGetLatestBigDeals();
  testGetLongShortRatio();
  testPlaceActiveOrder();
  testGetActiveOrder();
  testCancelActiveOrder();
  testCancelAllActiveOrders();
  testUpdateActiveOrder();
  testGetRealTimeActiveOrder();
  testPlaceConditionalOrder();
  testGetConditionalOrders();
  testCancelConditionalOrder();
  testCancelAllConditionalOrders();
  testUpdateConditionalOrder();
  testGetConditionalOrder();
  testGetPosition();
  testSetMargin();
  testSetTradingStop();
  testSetLeverage();
  testGetUserTradingRecords();
  testGetUserClosedProfit();
  testGetRiskLimit();
  testSetRiskLimit();
  testGetFundingRate();
  testGetPreviousFundingFee();
  testGetPredictedFundingRateAndFundingFee();
  testGetApiKeyInfo();
  testGetUserLCP();
  testGetWalletBalance();
  testGetWalletFundRecords();
  testGetWithdrawalRecords();
  testGetAssetExchangeRecords();
  testGetServerTime();
  testGetAnnouncement();
}