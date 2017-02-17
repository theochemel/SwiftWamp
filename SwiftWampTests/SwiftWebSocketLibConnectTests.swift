//
//  SwiftWebSocketLibConnectTests.swift
//  SwiftWamp
//
//  Created by Dany Sousa on 17/02/2017.
//  Copyright © 2017 danysousa. All rights reserved.
//

import XCTest
@testable import SwiftWamp

class SwiftWebSocketLibConnectTests: XCTestCase, SwampSessionDelegate {

    let socketUrl: String = "ws://localhost:8080/ws"
    let defaultRealm: String = "restrictive-realm"
    let authMethods: [String] = ["wampcra"]
    let authID: String = "homer"
    let goodCraSecret: String = "secret123"
    var craSecret: String = "secret123"


    var transport: SwiftWebSocketTransport?
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
        self.expectation = [:]
        self.transport = SwiftWebSocketTransport(wsEndpoint: self.socketUrl)
        self.transport?.enableDebug = true
        session = SwampSession(realm: self.defaultRealm, transport: transport!, authmethods: self.authMethods, authid: authID)
        session?.delegate = self
    }

    override func tearDown() {
        super.tearDown()

        if self.sessionID == nil {
            return
        }

        self.startedDisconnectProcess = true
        self.expectation["disconnectProcessEnded"] = expectation(description: "disconnectProcessEnded")

        session!.disconnect()

        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
            self.startedConnectProcess = false
        })
    }

    func testWithGoodCra() {
        self.expectation["connectionProcessEnded"] = expectation(description: "connectionProcessEnded")
        self.startedConnectProcess = true
        self.session!.connect()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertTrue(self.session!.isConnected())
            XCTAssertNotNil(self.sessionID)
            self.startedConnectProcess = false
        })
    }

    func testWithBadCra() {
        self.craSecret = "pokpok"
        self.expectation["connectionProcessEnded"] = expectation(description: "connectionProcessEnded")
        self.startedConnectProcess = true
        self.session!.connect()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertFalse(self.session!.isConnected())
            XCTAssertNil(self.sessionID)
            self.startedConnectProcess = false
        })
    }


    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String {
        return SwampCraAuthHelper.sign(self.craSecret, challenge: extra["challenge"] as! String)
    }

    func swampSessionConnected(_ session: SwampSession, sessionId: NSNumber) {
        self.sessionID = sessionId

        if self.craSecret != self.goodCraSecret {
            XCTFail()
        }
        self.expectation["connectionProcessEnded"]?.fulfill()
    }

    func swampSessionEnded(_ reason: String) {
        if self.startedDisconnectProcess {
            self.expectation["disconnectProcessEnded"]?.fulfill()
            XCTAssertEqual(reason, "wamp.close.normal")
            return
        } else if self.startedConnectProcess {
            self.expectation["connectionProcessEnded"]?.fulfill()

            if self.craSecret == self.goodCraSecret {
                XCTFail()
            }
            return
        }
        // Unexpected disconnection
        XCTFail()
    }
}
