//
//  Helpers.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import Foundation
import CoreBluetooth

extension Data {
    var string: String? {
        String(data: self, encoding: .utf8)
    }
}

internal protocol CharacteristicController {
    var characteristic: CBMutableCharacteristic { get }
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleSubscribeToCharacteristic(on peripheral: CBPeripheralManager)
}

internal protocol ServiceController {
    var service: CBMutableService { get }
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleSubscribeToCharacteristic(characteristic: CBMutableCharacteristic, on peripheral: CBPeripheralManager)
}

internal class MovmentCharacteristic: CharacteristicController {
    
    internal let characteristic: CBMutableCharacteristic
    internal weak var peripheral: CBPeripheralManager?
    
    internal init(characteristic: CBMutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "0x3232"), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])) {
        self.characteristic = characteristic
    }
    
    internal func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        print(request.value?.string ?? "")
    }
    
    internal func handleSubscribeToCharacteristic(on peripheral: CBPeripheralManager) {
        self.peripheral = peripheral
    }
    
    internal func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        print(request.value?.string ?? "")
    }
}

internal class MotionService: ServiceController {
    let service: CBMutableService
    let movmentCharacteristic = MovmentCharacteristic()
    
    internal init(service: CBMutableService) {
        self.service = service
        service.characteristics = [movmentCharacteristic.characteristic]
    }
    
    internal func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        guard request.characteristic.uuid == movmentCharacteristic.characteristic.uuid else { fatalError("Invalid request") }
        movmentCharacteristic.handleReadRequest(request, peripheral: peripheral)
    }
    
   internal func handleSubscribeToCharacteristic(characteristic: CBMutableCharacteristic, on peripheral: CBPeripheralManager) {
        guard characteristic.uuid == movmentCharacteristic.characteristic.uuid else { fatalError("Invalid request") }
        movmentCharacteristic.handleSubscribeToCharacteristic(on: peripheral)
    }
    
    internal func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {}
}
