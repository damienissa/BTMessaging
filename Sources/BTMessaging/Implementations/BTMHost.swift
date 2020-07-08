//
//  BTMHost.swift
//  BTMHost
//
//  Created by Dima Virych on 18.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import CoreBluetooth

public protocol BTMHostDelegate: class {
    
    func host(_ host: BTMHost, didReceiveConnectionFrom central: CBCentral)
    func host(_ host: BTMHost, didReceiveDisconnectionFrom central: CBCentral)
    func host(_ host: BTMHost, didReceiveData data: Data, for characteristic: Characteristic)
}

public final class BTMHost: NSObject {
    
    public enum Error: Swift.Error {
        case peripheralAlreadyOn
        case peripheralAlreadyOff
    }
    
    private let service: CBMutableService
    private let serial = SerialQueue()
    private var peripheral: CBPeripheralManager?
    private let peripheralName: String
    private var centrals: [CBCentral] = []
    private var charType: Characteristic.Type
    private var dataHelper: BigDataHelper?
    private var started = false
    
    
    public weak var delegate: BTMHostDelegate?
    
    public init(service: CBUUID = CBUUID(string: "0x101D"), hostName: String, type: Characteristic.Type) {
        self.peripheralName = hostName
        self.charType = type
        self.service = CBMutableService(type: service, primary: true)
        
        super.init()
    }
    
    public func turnOn() throws {
        
        if peripheral != nil { throw Error.peripheralAlreadyOn }
        peripheral = CBPeripheralManager(delegate: self, queue: .main)
    }
    
    public func turnOff() throws {
        
        started = false
        
        if peripheral == nil || peripheral?.state != .poweredOn { throw Error.peripheralAlreadyOff }
    
        peripheral?.stopAdvertising()
        peripheral = nil
    }
    
    private func startAdvertising() {
        
        print("Starting advertising")
        if started {
            return
        }
        started = true
        service.characteristics = charType.all()
        peripheral?.add(service)
        
        let advertisementData: [String: Any] = [CBAdvertisementDataLocalNameKey: peripheralName,
                                                CBAdvertisementDataServiceUUIDsKey: [service.uuid]]
        peripheral?.startAdvertising(advertisementData)
    }
}


// MARK: - BTMessaging

extension BTMHost: BTMessaging {
    
    public func send(_ data: String, for characteristic: Characteristic) {
        
        guard data.count > BTMessagingSettings.chunkSize else {
            if let d = data.data(using: .utf8) {
                serial.addOperation { [weak self] in
                    self?.send(data: d, for: characteristic)
                }
            }
            
            return serial.startIfNeeded()
        }
        
        let datas = data.chunkedData(with: BTMessagingSettings.chunkSize)
        datas.forEach { dat in
            serial.addOperation { [weak self] in
                self?.send(data: dat, for: characteristic)
            }
        }
        
        serial.startIfNeeded()
    }
    
    private func send(data: Data, for characteristic: Characteristic) {
        
        if let char = service.characteristics?.first(where: { $0.uuid == characteristic.char.uuid }) {
            peripheral?.updateValue(data, for: char as! CBMutableCharacteristic, onSubscribedCentrals: centrals)
        }
    }
}


// MARK: - CBPeripheralManagerDelegate

extension BTMHost: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .poweredOn:
            print("Peirpheral is on")
            startAdvertising()
        case .poweredOff:
            print("Peripheral \(peripheral.description) is off")
        case .resetting:
            print("Peripheral \(peripheral.description) is resetting")
        case .unauthorized:
            print("Peripheral \(peripheral.description) is unauthorized")
        case .unsupported:
            print("Peripheral \(peripheral.description) is unsupported")
        case .unknown:
            print("Peripheral \(peripheral.description) state unknown")
        @unknown default:
            fatalError()
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
        print("\(#function)")
        peripheral.respond(to: request, withResult: .success)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        peripheral.respond(to: requests.first!, withResult: .success)
        
        let str = requests.first?.value?.string ?? ""
        if str.contains("Size: ") == true {
            dataHelper = BigDataHelper(with: { [weak self] (result) in
                guard let self = self, let data = result.data(using: .utf8), let id = requests.first?.characteristic.uuid.uuidString else { return }
                main {
                    if let char = self.charType.from(id) {
                        self.delegate?.host(self, didReceiveData: data, for: char)
                    }
                }
                self.dataHelper = nil
            })
        } else {
            if dataHelper == nil {
                if let data = requests.first?.value, let id = requests.first?.characteristic.uuid.uuidString {
                    main { [weak self] in
                        guard let self = self else { return }
                        if let char = self.charType.from(id) {
                            self.delegate?.host(self, didReceiveData: data, for: char)
                        }
                    }
                }
            }
        }
        
        dataHelper?.receive(requests.first!.value!)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("\(#function)")
        if !centrals.contains(central) {
            centrals.append(central)
        }
        
        main { [weak self] in
            
            guard let self = self else { return }
            
            self.delegate?.host(self, didReceiveConnectionFrom: central)
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
        main { [weak self] in
            
            guard let self = self else { return }
            
            self.delegate?.host(self, didReceiveDisconnectionFrom: central)
        }
    }
}
