//
//  SwampSession.swift
//

import Foundation
import SwiftyJSON

// MARK: Call callbacks
/**
 CallCallBack is a typealias for success call callback

 - Parameter details: A [String:Any] containing details about your call
 - Parameter results: An optional [Any] containing all your results
 - Parameter kwResults: [String: Any] Your result indexing by keyString
 */
public typealias CallCallback = (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void

/**
 ErrorCallCallback is a typealias for fail call callback

 - Parameter details: A [String:Any] containing details about your call
 - Parameter error: A String containing error message
 - Parameter args: An optional [Any] containing all your args
 - Parameter kwargs: [String: Any] Your args indexing by keyString
 */
public typealias ErrorCallCallback = (_ details: [String: Any], _ error: String, _ args: [Any]?, _ kwargs: [String: Any]?) -> Void

// MARK: Callee callbacks
// For now callee is irrelevant
//public typealias RegisterCallback = (registration: Registration) -> Void
//public typealias ErrorRegisterCallback = (details: [String: Any], error: String) -> Void
//public typealias SwampProc = (args: [Any]?, kwargs: [String: Any]?) -> Any
//public typealias UnregisterCallback = () -> Void
//public typealias ErrorUnregsiterCallback = (details: [String: Any], error: String) -> Void

// MARK: Subscribe callbacks
/**
 SubscribeCallback is a typealias for success subscribe callback

 - Parameter subscribe: An instance of Subscription describing your subscription (subscribe id, event callback, session...)
 */
public typealias SubscribeCallback = (_ subscription: Subscription) -> Void

/**
 ErrorSubscribeCallback is a typealias for fail subscribe callback

 - Parameter details: A [String:Any] containing details about your subscribe request
 - Parameter error: A String containing error message
 */
public typealias ErrorSubscribeCallback = (_ details: [String: Any], _ error: String) -> Void

/**
 EventCallback is called for each published event on the topic

 - Parameter details: A [String:Any] containing details about your subscribe request
 - Parameter result: An optional [Any] containing all the parameters of the published event
 - Parameter kwResults: [String: Any] Your args indexing by keyString
 */
public typealias EventCallback = (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void

/**
 UnsubscribeCallback is called when your unsubscribe request succeeded
 */
public typealias UnsubscribeCallback = () -> Void

/**
 ErrorUnsubscribeCallback is called if your unsubscribe request failed

 - Parameter details: A [String: Any] containing details about your subscribe request
 - Parameter error: A String containing error message
 */
public typealias ErrorUnsubscribeCallback = (_ details: [String: Any], _ error: String) -> Void

// MARK: Publish callbacks

/**
 PublishCallback is called when your publish succeeded
 */
public typealias PublishCallback = () -> Void

/**
 ErrorPublishCallback is called if your publish failed

 - Parameter details: A [String: Any] containing details about your publish request
 - Parameter error: A String containing error message
 */
public typealias ErrorPublishCallback = (_ details: [String: Any], _ error: String) -> Void

// TODO: Expose only an interface (like Cancellable) to user

// For now callee is irrelevant
//public class Registration {
//    private let session: SwampSession
//}

public protocol SwampSessionDelegate {
    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String

    func swampSessionConnected(_ session: SwampSession, sessionId: NSNumber)

    func swampSessionEnded(_ reason: String)
}

/**
 SwampSession is the object connecting all the session data and methods, use this class to connect to the wamp server,
 call, register, unregister, publish, subscribe and unsubscribe
 */

open class SwampSession: SwampTransportDelegate {
    // MARK: Public typealiases

    // MARK: delegate
    /**
     The delegate must implement SwampSessionDelegate and is informed when the session is connected, disconnected or if
     is challenged by the server for an authentication extra data (like ticket)
     */
    open var delegate: SwampSessionDelegate?

    // MARK: Constants
    // No callee role for now
    fileprivate let supportedRoles: [SwampRole] = [SwampRole.Caller, SwampRole.Subscriber, SwampRole.Publisher]
    fileprivate let clientName = "SwiftWamp-dev-0.2.1"

    // MARK: Members
    fileprivate let realm: String
    fileprivate let transport: SwampTransport
    fileprivate let authmethods: [String]?
    fileprivate let authid: String?
    fileprivate let authrole: String?
    fileprivate let authextra: [String: Any]?
    fileprivate var autoReconnect: Bool = false

    // MARK: State members
    fileprivate var currRequestId: Int = 1

    // MARK: Session state
    fileprivate var serializer: SwampSerializer?
    fileprivate var sessionId: NSNumber?
    fileprivate var routerSupportedRoles: [SwampRole]?

    // MARK: Call role
    //                         requestId
    fileprivate var callRequests: [Int: (callback: CallCallback, errorCallback: ErrorCallCallback)] = [:]

    // MARK: Subscriber role
    //                              requestId
    fileprivate var subscribeRequests: [Int: (callback: SubscribeCallback, errorCallback: ErrorSubscribeCallback, eventCallback: EventCallback)] = [:]
    //                          subscription
    fileprivate var subscriptions: [NSNumber: Subscription] = [:]
    //                                requestId
    fileprivate var unsubscribeRequests: [Int: (subscription: NSNumber, callback: UnsubscribeCallback, errorCallback: ErrorUnsubscribeCallback)] = [:]

    // MARK: Publisher role
    //                            requestId
    fileprivate var publishRequests: [Int: (callback: PublishCallback, errorCallback: ErrorPublishCallback)] = [:]

    /**
      The default constructor just save all parameters of the session

      - Parameter realm: String describing the realm name
      - Parameter transport: The transport must implement the SwampTransport protocol, actually you can have an example
        with WebSocketSwampTransport
      - Parameter authmethods: the list of authmethods you support
      - Parameter authid: An optional String communicated to the server during the connection for identify your client
      - Parameter authrole: An optional String communicated to the server during the connection for ask the permissions
      associated to this role
      - Parameter authextra: An optional Dictionary containing all the extra data need to be communicated during the
      connection
     */
    required public init(realm: String,
                         transport: SwampTransport,
                         authmethods: [String]? = nil,
                         authid: String? = nil,
                         authrole: String? = nil,
                         authextra: [String: Any]? = nil) {
        self.realm = realm
        self.transport = transport
        self.authmethods = authmethods
        self.authid = authid
        self.authrole = authrole
        self.authextra = authextra
        self.transport.delegate = self
    }

    // MARK: Public API

    /**
     isConnected is a simple getter of state of session, it's a simple check if the current session have a sessionId

     - Returns: Bool, true if the session is connected to the server
     */
    final public func isConnected() -> Bool {
        return self.sessionId != nil
    }

    /**
     connect use the transport instance to connect client to the server.

     When the connection process is finished, SwampSession call the appropriate SwampSessionDelegate method
     SwampSession is informed by SwampTransportDelegate if the connection failed or succeed
     */
    final public func connect(autoReconnect: Bool = false) {
        self.autoReconnect = autoReconnect
        self.transport.connect()
    }

    /**
     disconnect use the transport instance to disconnect client to the server.

     When the disconnection process is finished, SwampSession call the appropriate SwampSessionDelegate method
     SwampSession is informed by SwampTransportDelegate when the transport is disconnected
    */
    final public func disconnect(_ reason: String = "wamp.error.close_realm") {
        if self.isConnected() {
            self.sendMessage(GoodbyeSwampMessage(details: [:], reason: reason))
        }
    }

    // MARK: Caller role
    /**
     Call is the method to use for remote procedure calls.
     For call a remote procedure, you can specify the procedure name, optional options, optional args/kwargs,
     a success and an error callback.

     - Parameter proc: The procedure name in a String
     - Parameter options: Optional dict containing options requested for this call
     - Parameter args: Optional list [Any]? containing all the argument you communicate for this call
     - Parameter kwargs: Optional dict containing all the argument you communicate for this call indexing by key
     - Parameter onSuccess: it's the function called if the RPC succeed
        the type of this function is the typealias CallCallback, here is the complete signature :
        (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void
     - Parameter onError: it's the function called if the RPC failed
        the type of this function is the typealias ErrorCallCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String, _ args: [Any]?, _ kwargs: [String: Any]?) -> Void
     */
    open func call(_ proc: String,
                   options: [String: Any] = [:],
                   args: [Any]? = nil,
                   kwargs: [String: Any]? = nil,
                   onSuccess: @escaping CallCallback,
                   onError: @escaping ErrorCallCallback) {
        if !self.isConnected() {
            return
        }
        let callRequestId = self.generateRequestId()
        // Tell router to dispatch call
        self.sendMessage(CallSwampMessage(requestId: callRequestId, options: options, proc: proc, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.callRequests[callRequestId] = (callback: onSuccess, errorCallback: onError)
    }

    // MARK: Callee role
    // For now callee is irrelevant
    // public func register(proc: String, options: [String: AnyObject]=[:], onSuccess: RegisterCallback, onError: ErrorRegisterCallback, onFire: SwampProc) {
    // }

    // MARK: Subscriber role

    /**
     Subscribe send a subscribe request to the server and, in success case, save the event callback in subscription
     instance.
     For subscribe to a topic, you can specify the topic name, optional options, success/error callback and event
     callback.
     If you subscribe request is accepted, the success callback is called and your event callback must be called for
     each publish received for this topic

     - Parameter topic: A topic name String
     - Parameter options: Optional dict containing options requested for this subscribe
     - Parameter onSuccess: it's the function called if the subscribe request succeed
        the type of this function is the typealias SubscribeCallback, here is the complete signature :
        (_ subscription: Subscription) -> Void
     - Parameter onError: it's the function called if the subscribe request failed
        the type of this function is the typealias ErrorSubscribeCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String) -> Void
     - Parameter EventCallback: it's the function called for each publish sent to this topic
        the type of this function is the typealias EventCallback, here is the complete signature :
        (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void
     */
    open func subscribe(_ topic: String,
                        options: [String: Any] = [:],
                        onSuccess: @escaping SubscribeCallback,
                        onError: @escaping ErrorSubscribeCallback,
                        onEvent: @escaping EventCallback) {
        if !self.isConnected() {
            return
        }
        // TODO: assert topic is a valid WAMP uri
        let subscribeRequestId = self.generateRequestId()
        // Tell router to subscribe client on a topic
        self.sendMessage(SubscribeSwampMessage(requestId: subscribeRequestId, options: options, topic: topic))
        // Store request ID to handle result
        self.subscribeRequests[subscribeRequestId] = (callback: onSuccess, errorCallback: onError, eventCallback: onEvent)
    }

    /**
     Unsubscribe is internal because only a Subscription object can call this.
     this function send an unsubscribe request to the server.
     For unsubscribe to a topic, you must specify the subscribe id, a success and an error callback.

     - Parameter subscription: the subscribe id
     - Parameter onSuccess: it's the function called if the unsubscribe request succeed
        the type of this function is the typealias UnsubscribeCallback, here is the complete signature :
        () -> Void
     - Parameter onError: it's the function called if the unsubscribe request failed
        the type of this function is the typealias ErrorUnsubscribeCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String) -> Void
     */
    internal func unsubscribe(_ subscription: NSNumber,
                              onSuccess: @escaping UnsubscribeCallback,
                              onError: @escaping ErrorUnsubscribeCallback) {
        if !self.isConnected() {
            return
        }

        let unsubscribeRequestId = self.generateRequestId()
        // Tell router to unsubscribe me from some subscription
        self.sendMessage(UnsubscribeSwampMessage(requestId: unsubscribeRequestId, subscription: subscription))
        // Store request ID to handle result
        self.unsubscribeRequests[unsubscribeRequestId] = (subscription, onSuccess, onError)
    }

    // MARK: Publisher role

    /**
     Publish send an event (with args) on a topic.
     This publish is without acknowledging, and doesn't have callback params, if you want a success/error callback,
     an other publish function exist with acknowledging

     - Parameter topic: A String describing the topic name
     - Parameter options: An optional [String: Any] dict containing all options about the publish
     - Parameter args: An optional list of all arguments you want to communicate with this publish
     - Parameter kwargs: An optional dict of all arguments you want to communicate with this publish indexing by key
     */
    open func publish(_ topic: String, options: [String: Any] = [:], args: [Any]? = nil, kwargs: [String: Any]? = nil) {
        if !self.isConnected() {
            return
        }
        // TODO: assert topic is a valid WAMP uri
        let publishRequestId = self.generateRequestId()
        // Tell router to publish the event
        self.sendMessage(PublishSwampMessage(requestId: publishRequestId, options: options, topic: topic, args: args, kwargs: kwargs))
        // We don't need to store the request, because it's unacknowledged anyway
    }

    /**
     Publish send an event (with args) on a topic.
     This publish is with acknowledging, you must specify success and error callbacks, if you don't care about the
     publish state, you can call the other publish methods without acknowledging

     - Parameter topic: A String describing the topic name
     - Parameter options: An optional [String: Any] dict containing all options about the publish
     - Parameter args: An optional list of all arguments you want to communicate with this publish
     - Parameter kwargs: An optional dict of all arguments you want to communicate with this publish indexing by key
     - Parameter onSuccess: it's the function called if the publish request succeed
        the type of this function is the typealias PublishCallback, here is the complete signature :
        () -> Void
     - Parameter onError: it's the function called if the publish request failed
        the type of this function is the typealias ErrorPublishCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String) -> Void
     */
    open func publish(_ topic: String,
                      options: [String: Any] = [:],
                      args: [Any]? = nil,
                      kwargs: [String: Any]? = nil,
                      onSuccess: @escaping PublishCallback,
                      onError: @escaping ErrorPublishCallback) {
        if !self.isConnected() {
            return
        }
        // add acknowledge to options, so we get callbacks
        var options = options
        options["acknowledge"] = true
        // TODO: assert topic is a valid WAMP uri
        let publishRequestId = self.generateRequestId()
        // Tell router to publish the event
        self.sendMessage(PublishSwampMessage(requestId: publishRequestId, options: options, topic: topic, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.publishRequests[publishRequestId] = (callback: onSuccess, errorCallback: onError)
    }

    // MARK: SwampTransportDelegate

    open func swampTransportDidDisconnect(_ error: NSError?, reason: String?) {
        if reason != nil {
            self.delegate?.swampSessionEnded(reason!)
        } else if error != nil {
            self.delegate?.swampSessionEnded("Unexpected error: \(error!.description)")
        } else {
            self.delegate?.swampSessionEnded("Unknown error.")
            if self.autoReconnect {
                self.connect()
            }
        }
    }

    open func swampTransportDidConnectWithSerializer(_ serializer: SwampSerializer) {
        self.serializer = serializer
        // Start session by sending a Hello message!

        var roles = [String: Any]()
        for role in self.supportedRoles {
            // For now basic profile, (demands empty dicts)
            roles[role.rawValue] = [:]
        }

        var details: [String: Any] = [:]

        if let authmethods = self.authmethods {
            details["authmethods"] = authmethods
        }
        if let authid = self.authid {
            details["authid"] = authid
        }
        if let authrole = self.authrole {
            details["authrole"] = authrole
        }
        if let authextra = self.authextra {
            details["authextra"] = authextra
        }

        details["agent"] = self.clientName
        details["roles"] = roles
        self.sendMessage(HelloSwampMessage(realm: self.realm, details: details))
    }

    open func swampTransportReceivedData(_ data: Data) {
        if let payload = self.serializer?.unpack(data), let message = SwampMessages.createMessage(payload) {
            self.handleMessage(message)
        }
    }

    fileprivate func handleMessage(_ message: SwampMessage) {
        switch message {
                // MARK: Auth responses
        case let message as ChallengeSwampMessage:
            if let authResponse = self.delegate?.swampSessionHandleChallenge(message.authMethod, extra: message.extra) {
                self.sendMessage(AuthenticateSwampMessage(signature: authResponse, extra: [:]))
            } else {
                print("There was no delegate, aborting.")
                self.abort()
            }
                // MARK: Session responses
        case let message as WelcomeSwampMessage:
            self.sessionId = message.sessionId
            let routerRoles = message.details["roles"]! as! [String: [String: Any]]
            self.routerSupportedRoles = routerRoles.keys.map {
                SwampRole(rawValue: $0)!
            }
            self.delegate?.swampSessionConnected(self, sessionId: message.sessionId)
        case let message as GoodbyeSwampMessage:
            if message.reason != "wamp.error.goodbye_and_out" {
                // Means it's not our initiated goodbye, and we should reply with goodbye
                self.sendMessage(GoodbyeSwampMessage(details: [:], reason: "wamp.error.goodbye_and_out"))
            }
            self.transport.disconnect(message.reason)
        case let message as AbortSwampMessage:
            self.transport.disconnect(message.reason)
                // MARK: Call role
        case let message as ResultSwampMessage:
            let requestId = message.requestId
            if let (callback, _) = self.callRequests.removeValue(forKey: requestId) {
                callback(message.details, message.results, message.kwResults)
            } else {
                // TODO: log this erroneous situation
            }
                // MARK: Subscribe role
        case let message as SubscribedSwampMessage:
            let requestId = message.requestId
            if let (callback, _, eventCallback) = self.subscribeRequests.removeValue(forKey: requestId) {
                // Notify user and delegate him to unsubscribe this subscription
                let subscription = Subscription(session: self, subscription: message.subscription, onEvent: eventCallback)
                callback(subscription)
                // Subscription succeeded, we should store event callback for when it's fired
                self.subscriptions[message.subscription] = subscription
            } else {
                // TODO: log this erroneous situation
            }
        case let message as EventSwampMessage:
            if let subscription = self.subscriptions[message.subscription] {
                subscription.eventCallback(message.details, message.args, message.kwargs)
            } else {
                // TODO: log this erroneous situation
            }
        case let message as UnsubscribedSwampMessage:
            let requestId = message.requestId
            if let (subscription, callback, _) = self.unsubscribeRequests.removeValue(forKey: requestId) {
                if let subscription = self.subscriptions.removeValue(forKey: subscription) {
                    subscription.invalidate()
                    callback()
                } else {
                    // TODO: log this erroneous situation
                }
            } else {
                // TODO: log this erroneous situation
            }
        case let message as PublishedSwampMessage:
            let requestId = message.requestId
            if let (callback, _) = self.publishRequests.removeValue(forKey: requestId) {
                callback()
            } else {
                // TODO: log this erroneous situation
            }

                ////////////////////////////////////////////
                // MARK: Handle error responses
                ////////////////////////////////////////////
        case let message as ErrorSwampMessage:
            switch message.requestType {
            case SwampMessages.call:
                if let (_, errorCallback) = self.callRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error, message.args, message.kwargs)
                } else {
                    // TODO: log this erroneous situation
                }
            case SwampMessages.subscribe:
                if let (_, errorCallback, _) = self.subscribeRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case SwampMessages.unsubscribe:
                if let (_, _, errorCallback) = self.unsubscribeRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            case SwampMessages.publish:
                if let (_, errorCallback) = self.publishRequests.removeValue(forKey: message.requestId) {
                    errorCallback(message.details, message.error)
                } else {
                    // TODO: log this erroneous situation
                }
            default:
                return
            }
        default:
            return
        }
    }

    // MARK: Private methods

    fileprivate func abort() {
        if self.sessionId != nil {
            return
        }
        self.sendMessage(AbortSwampMessage(details: [:], reason: "wamp.error.system_shutdown"))
        self.transport.disconnect("No challenge delegate found.")
    }

    fileprivate func sendMessage(_ message: SwampMessage) {
        let marshalledMessage = message.marshal()
        let data = self.serializer!.pack(marshalledMessage as [Any])!
        self.transport.sendData(data)
    }

    fileprivate func generateRequestId() -> Int {
        self.currRequestId += 1
        return self.currRequestId
    }
}
