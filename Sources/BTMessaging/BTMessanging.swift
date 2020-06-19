//
//  BTMessanging.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum Characteristic {

    case data
    case custom(String)
    
    public static func from(_ string: String?) -> Characteristic {
        switch string {
        case "0x3232":
            return .data
        default:
            return string != nil ? .custom(string!) : .data
        }
    }
    
    public var char: CBMutableCharacteristic {
        switch self {
        case .data:
            return CBMutableCharacteristic(type: CBUUID(string: "0x3232"), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
        case let .custom(str):
            return CBMutableCharacteristic(type: CBUUID(string: str), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
        }
    }
}

public protocol BTMessanging {
    
    // MARK: - Max data length 512
    typealias DataHandler = (_ data: Data?, _ characteristic: Characteristic) -> Void
    
    func send(_ data: Data, for characteristic: Characteristic)
    func receive(_ handler: @escaping DataHandler)
}
