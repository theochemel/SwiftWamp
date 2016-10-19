//
//  SwiftWampTests.swift
//  SwiftWampTests
//
//  Created by Dany Sousa on 13/10/2016.
//  Copyright © 2016 danysousa. All rights reserved.
//

import XCTest
@testable import SwiftWamp

/**
 Here is test for SwiftWamp. Please launch the crossbar server in
 SwiftWampTests/CrossbarInstanceTest before running tests
 */

class SwiftWampTests: XCTestCase, SwampSessionDelegate {

    let socketUrl: String = "ws://localhost:8080/ws"
    let defaultRealm: String = "open-realm"
    let authMethods: [String] = ["anonymous"]

    var session: SwampSession?
    var sessionID: NSNumber? = nil
    var subscription: [String: Subscription] = [:]

    var expectation: [String: XCTestExpectation] = [:]
    var startedDisconnectProcess: Bool = false
    var startedConnectProcess: Bool = false

    /**
        This function is called before all tests but it's a test too

        Create a session and try to connect to crossbar, and check if the connection is established
     */
    override func setUp() {
        super.setUp()
        let transport: WebSocketSwampTransport = WebSocketSwampTransport(wsEndpoint: URL(string: self.socketUrl)!)
        session = SwampSession(realm: self.defaultRealm, transport: transport, authmethods: self.authMethods)
        session?.delegate = self

        self.expectation["connectionProcessEnded"] = expectation(description: "connectionProcessEnded")
        self.startedConnectProcess = true
        session!.connect()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertTrue(self.session!.isConnected())
            XCTAssertNotNil(self.sessionID)
            self.startedConnectProcess = false
        })
    }

    override func tearDown() {
        super.tearDown()

        self.startedDisconnectProcess = true
        self.expectation["disconnectProcessEnded"] = expectation(description: "disconnectProcessEnded")

        session!.disconnect()

        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
            self.startedConnectProcess = false
        })
    }

    func testCall() {
        /**
         Test with add
         */
        self.expectation["addCallSucceeded"] = expectation(description: "addCallSucceeded")
        session?.call("org.swamp.add", args: [1, 1], onSuccess: { details, results, kwResults in
            // result can be equal to 2
            XCTAssertEqual(results?[0] as? Int, 2)
            self.expectation["addCallSucceeded"]?.fulfill()
        }, onError: { details, error, args, kwargs in
            // No error possible
            XCTFail()
            self.expectation["addCallSucceeded"]?.fulfill()
        })
        // Wait callback call
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })

        /**
         Test with echo
         */
        self.expectation["addCallSucceeded"] = expectation(description: "addCallSucceeded")
        session?.call("org.swamp.echo", args: [1, 1], onSuccess: { details, results, kwResults in
            // result can be equal to [1, 1]
            XCTAssertEqual(results?[0] as! [Int], [1, 1])
            self.expectation["addCallSucceeded"]?.fulfill()
        }, onError: { details, error, args, kwargs in
            // No error possible
            XCTFail()
            self.expectation["addCallSucceeded"]?.fulfill()
        })
        // Wait callback call
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testCallFailed() {
        /**
         Test add remote call with a single param
         */
        self.expectation["addCallFailed"] = expectation(description: "addCallFailed")
        session?.call("org.swamp.add", args: [1], onSuccess: { details, results, kwResults in
            // Can't return a success
            XCTFail()
            self.expectation["addCallFailed"]?.fulfill()
        }, onError: { details, error, args, kwargs in
            // An error is expected
            XCTAssertEqual(error, "wamp.error.runtime_error")
            XCTAssertEqual(args![0] as! String, "add() missing 1 required positional argument: 'num2'")
            self.expectation["addCallFailed"]?.fulfill()
        })
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testSubscribeAndUnsubscibe() {
        self.expectation["heartbeatSubscribe"] = expectation(description: "heartbeatSubscribe")

        session?.subscribe("org.swamp.heartbeat",
                onSuccess: self.successSubscribeHeartbeatCallback,
                onError: self.errorSubscribeHeartbeatCallback,
                onEvent: self.eventSubscribeHeartbeatCallback)

        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func successSubscribeHeartbeatCallback(_ subscription: Subscription) -> Void {
        print("Subscribe succeded ============================")
        self.subscription["org.swamp.heartbeat"] = subscription
        print(subscription)
    }

    func errorSubscribeHeartbeatCallback(_ details: [String: Any], _ error: String) -> Void {
        print("Subscribe failed ============================")
        XCTFail()
        self.expectation["heartbeatSubscribe"]?.fulfill()
    }

    func eventSubscribeHeartbeatCallback(_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void {
        XCTAssertEqual(results![0] as! String, "Heartbeat!")
        self.subscription["org.swamp.heartbeat"]?.cancel({
            print("HERE =================================")
            self.expectation["heartbeatSubscribe"]?.fulfill()
        }, onError: { details, error in
            print(details)
            print(error)
            print("ERROR =================================")
            XCTFail()
        })
    }

    func testUnacknowledgedpublication() {
        session!.publish("org.swamp.some_publication", args: [1, 2, 3])
    }

    func testAcknowledgedpublication() {
        self.expectation["publishProcess"] = expectation(description: "publishProcess")
        session!.publish("org.swamp.some_publication", args: [1, 2, 3], onSuccess: {
            self.expectation["publishProcess"]?.fulfill()
        }, onError: { details, error in
            XCTFail()
            self.expectation["publishProcess"]?.fulfill()
        })

        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String {
        return ""
    }

    func swampSessionConnected(_ session: SwampSession, sessionId: NSNumber) {
        self.sessionID = sessionId
        print("===========+++++++++++++++++++++++++++=============" + String(describing: sessionId))
        self.expectation["connectionProcessEnded"]?.fulfill()
    }

    func swampSessionEnded(_ reason: String) {
        if self.startedDisconnectProcess {
            self.expectation["disconnectProcessEnded"]?.fulfill()
            XCTAssertEqual(reason, "wamp.close.normal")
            return
        } else if self.startedConnectProcess {
            self.expectation["connectionProcessEnded"]?.fulfill()
            XCTFail()
            return
        }

        // Unexpected disconnection
        XCTFail()
    }
}
