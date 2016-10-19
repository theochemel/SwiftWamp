//
//  YieldSwampMessageTests.swift
//  SwiftWamp
//
//  Created by Dany Sousa on 19/10/2016.
//  Copyright © 2016 danysousa. All rights reserved.
//

import XCTest
@testable import SwiftWamp

class YieldSwampMessageTests: XCTestCase {
    var yieldMessage: YieldSwampMessage?

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testInitWithValidPayload() {
        var yield = YieldSwampMessage(payload: [1, ["pok": 12], [12], ["pok2": 13]])
        XCTAssertEqual(yield.requestId, 1)

        yield = YieldSwampMessage(requestId: 1, options: ["pok": 12], args: [12], kwargs: ["pok2": 13])
        XCTAssertEqual(yield.requestId, 1)
    }
}
