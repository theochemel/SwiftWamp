# Change Log

## [0.2.2](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.2)
* Feat: Auto Reconnect option
* Feat: Subscription contain topic name, add function to change event callback for a subscription
* Feat: Add topic name in details subscription event callback if discole is set to true
* Fix: Remove SwampMessage factory and cast switch for perf increase 
* Fix: Change typedef for callbacks

## [0.2.1](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.1)
* Fix: Support Int64 subscribe Ids see [WAMP Id validation](http://autobahn.ws/python/_modules/autobahn/wamp/message.html) 
* Add some unit tests
* Add docstring for SwampSession
* Force use NSNull instead nil for serialization
* Fix: Swift 3 support (AnyObject -> Any)
* Fix: Crash if server isn't reachable

## [0.2.0](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.0)
Use source of [Swamp 0.1.0](https://github.com/iscriptology/swamp/releases/tag/0.1.0) and convert to Swift 3.
