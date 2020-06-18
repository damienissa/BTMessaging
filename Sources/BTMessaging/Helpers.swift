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

protocol CharacteristicController {
    var characteristic: CBMutableCharacteristic { get }
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleSubscribeToCharacteristic(on peripheral: CBPeripheralManager)
}

protocol ServiceController {
    var service: CBMutableService { get }
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleSubscribeToCharacteristic(characteristic: CBMutableCharacteristic, on peripheral: CBPeripheralManager)
}

class MovmentCharacteristic: CharacteristicController {
    
    let characteristic: CBMutableCharacteristic
    private weak var peripheral: CBPeripheralManager?
    
    init(characteristic: CBMutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "0x3232"), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])) {
        self.characteristic = characteristic
    }
    
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        print(request.value?.string ?? "")
    }
    
    func handleSubscribeToCharacteristic(on peripheral: CBPeripheralManager) {
        self.peripheral = peripheral
    }
    
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        print(request.value?.string ?? "")
    }
}


class MotionService: ServiceController {
    let service: CBMutableService
    let movmentCharacteristic = MovmentCharacteristic()
    
    init(service: CBMutableService = CBMutableService(type: CBUUID(string: "0x101D"), primary: true)) {
        self.service = service
        service.characteristics = [movmentCharacteristic.characteristic]
    }
    
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        guard request.characteristic.uuid == movmentCharacteristic.characteristic.uuid else { fatalError("Invalid request") }
        movmentCharacteristic.handleReadRequest(request, peripheral: peripheral)
    }
    
    func handleSubscribeToCharacteristic(characteristic: CBMutableCharacteristic, on peripheral: CBPeripheralManager) {
        guard characteristic.uuid == movmentCharacteristic.characteristic.uuid else { fatalError("Invalid request") }
        movmentCharacteristic.handleSubscribeToCharacteristic(on: peripheral)
    }
    
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {}
    
}
