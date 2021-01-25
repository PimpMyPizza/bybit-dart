## [1.4.0]

* Added parameter autoreconnect to automatically reconnect and resubscribe to the websocket topic when an unexpected WebSocket closure occurs.
* Removed `int WebSocketTimeout` and `int restTimeout` parameters and replaced them with a `Duration timeout` parameter.
* Minor doc changes

## [1.3.0]

* Added the possibility to make periodic REST API calls.
* All API responses from the server (Websockets and periodic REST) are merged into one single stream.
* See README.md for an adapted tutorial
* Minor bugfixed and typos in doc

## [1.2.0]

* Minor changes in the parameters type of the following functions:
  - placeConditionalOrder
  - updateConditionalOrder
  prices and quantities parameters are now of type double/int
* Minor doc changes

## [1.1.0]

* Added new endpoints connections
  - getMarkPriceKLine
  - getOpenInterest
  - getLatestBigDeals
  - getLongShortRatio
* Minor bug-fixes

## [1.0.0]

* More doc, static analysis and other minor changes

## [0.5.0]

* API responses are now automatically mapped to JSON objects
* ByBit object is no more a singleton.
* More doc

## [0.4.0]

* Removed flutter dependency
* Endpoint tests automation
* Documentation of all endpoints parameters

## [0.3.0]

* Enabled Web support
* Added some doc

## [0.2.0]

* Adapted formating
* Added some doc
* Fixed bug with wrong log level
* Web version still has to be debugged

## [0.1.0]

* First version
* WebSocket and HTTPS (REST) communication
* Only a few endpoints were tested
