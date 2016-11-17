//
//  UnsubscribedSwampMessage.swift
//  Pods
//
//  Created by Yossi Abraham on 24/08/2016.
//
//

import Foundation

/// [UNSUBSCRIBED, requestId|number]

class UnsubscribedSwampMessage: SwampMessage {

    let type: SwampMessageType = .unsubscribed
    let requestId: Int

    init(requestId: Int) {
        self.requestId = requestId
    }

    // MARK: SwampMessage protocol

    required init(payload: [Any]) {
        self.requestId = payload[0] as! Int
    }

    func marshal() -> [Any] {
        return [self.type.rawValue, self.requestId]
    }
}
