//
//  File.swift
//  
//
//  Created by Dima Virych on 22.06.2020.
//

import Foundation

public struct BTMDevice {
    
    public let uuid: String
    public let name: String
    public let rssi: Int
    
    internal init(from data: (String, String, Int)) {
        self.name = data.0
        self.uuid = data.1
        self.rssi = data.2
    }
}
