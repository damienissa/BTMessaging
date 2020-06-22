//
//  BTMessaging.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol Characteristic {
    
    var char: CBMutableCharacteristic { get }
    
    static func from(_ string: String?) -> Self?
    static func all() -> [CBMutableCharacteristic]
}

public protocol BTMessaging {
    
    // MARK: - Max data length 512
    
    func send(_ data: String, for characteristic: Characteristic)
}
