//
//  RegisteredSwampMessage.swift
//  Pods
//
//  Created by Yossi Abraham on 01/09/2016.
//
//

import Foundation

/// [REGISTERED, requestId|number, registration|number]
class RegisteredSwampMessage: SwampMessage {

    let type: SwampMessageType = .registered
    let requestId: Int
    let registration: NSNumber

    init(requestId: Int, registration: NSNumber) {
        self.requestId = requestId
        self.registration = registration
    }

    // MARK: SwampMessage protocol

    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
        self.registration = payload[1] as! NSNumber
    }

    func marshal() -> [Any] {
        return [self.type.rawValue, self.requestId, self.registration]
    }
}
