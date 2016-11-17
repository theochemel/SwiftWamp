//
//  SwampMessageType.swift
//  Defines all swamp messages, and provide basic factory function for each one
//
//  Created by Yossi Abraham on 18/08/2016.
//  Copyright © 2016 Yossi Abraham. All rights reserved.
//

enum SwampMessageType: Int {

    // MARK: Basic profile messages

    case hello = 1
    case welcome = 2
    case abort = 3
    case goodbye = 6

    case error = 8

    case publish = 16
    case published = 17
    case subscribe = 32
    case subscribed = 33
    case unsubscribe = 34
    case unsubscribed = 35
    case event = 36

    case call = 48
    case result = 50
    case register = 64
    case registered = 65
    case unregister = 66
    case unregistered = 67
    case invocation = 68
    case yield = 70

    // MARK: Advance profile messages
    case challenge = 4
    case authenticate = 5

    /// payload consists of all data related to a message, WIHTHOUT the first one - the message identifier
    typealias WampMessageFactory = (_ payload: [Any]) -> SwampMessage

    // Split into 2 dictionaries because Swift compiler thinks a single one is too complex
    // Perhaps find a better solution in the future

//    fileprivate static let mapping: [SwampMessageType: WampMessageFactory] = [
//            SwampMessageType.error: ErrorSwampMessage.init,
//
//            // Session
//            SwampMessageType.hello: HelloSwampMessage.init,
//            SwampMessageType.welcome: WelcomeSwampMessage.init,
//            SwampMessageType.abort: AbortSwampMessage.init,
//            SwampMessageType.goodbye: GoodbyeSwampMessage.init,
//
//            // Auth
//            SwampMessageType.challenge: ChallengeSwampMessage.init,
//            SwampMessageType.authenticate: AuthenticateSwampMessage.init,
//
//            // RPC
//            SwampMessageType.call: CallSwampMessage.init,
//            SwampMessageType.result: ResultSwampMessage.init,
//            SwampMessageType.register: RegisterSwampMessage.init,
//            SwampMessageType.registered: RegisteredSwampMessage.init,
//            SwampMessageType.invocation: InvocationSwampMessage.init,
//            SwampMessageType.yield: YieldSwampMessage.init,
//            SwampMessageType.unregister: UnregisterSwampMessage.init,
//            SwampMessageType.unregistered: UnregisteredSwampMessage.init,
//
//            // PubSub
//            SwampMessageType.publish: PublishSwampMessage.init,
//            SwampMessageType.published: PublishedSwampMessage.init,
//            SwampMessageType.event: EventSwampMessage.init,
//            SwampMessageType.subscribe: SubscribeSwampMessage.init,
//            SwampMessageType.subscribed: SubscribedSwampMessage.init,
//            SwampMessageType.unsubscribe: UnsubscribeSwampMessage.init,
//            SwampMessageType.unsubscribed: UnsubscribedSwampMessage.init
//    ]
//
//
//    static func createMessage(_ payload: [Any]) -> SwampMessage? {
//        if let messageType = SwampMessageType(rawValue: payload[0] as! Int) {
//            if let messageFactory = mapping[messageType] {
//                return messageFactory(Array(payload[1 ..< payload.count]))
//            }
//        }
//        return nil
//    }
}
