//
//  Helpers.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import Foundation
import CoreBluetooth

internal func main(_ comp: @escaping () -> Void) {
    DispatchQueue.main.async(execute: comp)
}

extension Data {
    var string: String? {
        String(data: self, encoding: .utf8)
    }
}
