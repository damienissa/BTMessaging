//
//  BTMessanging.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol Characteristic {
    var char: CBMutableCharacteristic { get }
    static func from(_ string: String?) -> Self
}

public protocol BTMessanging {
    
    // MARK: - Max data length 512
    typealias DataHandler = (_ data: Data?, _ characteristic: Characteristic) -> Void
    
    func send(_ data: Data, for characteristic: Characteristic)
    func receive(_ handler: @escaping DataHandler)
}
