//
//  JSONSwampSerializerTests.swift
//  SwiftWamp
//
//  Created by Dany Sousa on 19/10/2016.
//  Copyright © 2016 danysousa. All rights reserved.
//

import XCTest
@testable import SwiftWamp

class JSONSwampSerializerTests: XCTestCase {
    var serializer: JSONSwampSerializer?

    override func setUp() {
        super.setUp()
        self.serializer = JSONSwampSerializer()
    }

    func testPackWithValidData() {
        let data: [Any] = ["asd", 123, -4567, "", NSNumber(value: 12), NSNull(), [""]]
        let result = self.serializer!.pack(data)
        XCTAssertNotNil(result)
    }

    func testPackWithInvalidData() {
        var data: [Any] = [NSNumber(value: 12).int64Value]
        var result = self.serializer!.pack(data)
        XCTAssertNil(result)

        data = [("a", "b")]
        result = self.serializer!.pack(data)
        XCTAssertNil(result)
    }

    func testUnpack() {
        let data: [Any] = ["asd", "123", "-4567", ""]
        let pack = self.serializer!.pack(data)
        let unpack = self.serializer!.unpack(pack!)!
        for (key, value) in data.enumerated() {
            XCTAssertEqual(value as! String, unpack[key] as! String)
        }
    }
}
