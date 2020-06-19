//
//  Host.swift
//  Host
//
//  Created by Dima Virych on 18.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import CoreBluetooth

public final class Host: NSObject {
    
    public enum Error: Swift.Error {
        case peripheralAlreadyOn
        case peripheralAlreadyOff
    }
    
    private let serial = SerialQueue()
    private(set) var peripheral: CBPeripheralManager!
    private let peripheralName: String
    private var serviceControllers: [ServiceController] = []
    private var centrals: [CBCentral] = []
    private var handler: BTMessaging.DataHandler?
    private var charType: Characteristic.Type
    private var dataHelper: BigDataHelper?
    
    public init(service: CBUUID = CBUUID(string: "0x101D"), peripheralName: String, type: Characteristic.Type) {
        self.peripheralName = peripheralName
        self.charType = type
        
        super.init()
        registerServiceController(
            MotionService(service: CBMutableService(type: service,
                                                    primary: true)
            )
        )
    }
    
    public func turnOn() throws {
        
        if peripheral != nil { throw Error.peripheralAlreadyOn }
        peripheral = CBPeripheralManager(delegate: self, queue: .main)
    }
    
    public func turnOff() throws {
        
        if peripheral == nil || peripheral.state != .poweredOn { throw Error.peripheralAlreadyOff }
        serviceControllers = []
        peripheral.stopAdvertising()
        peripheral = nil
    }
    
    private func registerServiceController(_ serviceController: ServiceController) {
        
        serviceControllers.append(serviceController)
    }
    
    private func startAdvertising() {
        
        print("Starting advertising")
        
        serviceControllers
            .map { $0.service }
            .forEach { peripheral.add($0) }
        
        let advertisementData: [String: Any] = [CBAdvertisementDataLocalNameKey: peripheralName,
                                                CBAdvertisementDataServiceUUIDsKey: serviceControllers.map({ $0.service.uuid })]
        peripheral.startAdvertising(advertisementData)
    }
}


// MARK: - BTMessaging

extension Host: BTMessaging {
    
    public func send(_ data: [Data], for characteristic: Characteristic) {
        
        data.forEach { dat in
            serial.addOperation { [weak self] in
            
                self?.send(data: dat, for: characteristic)
            }
        }
        
        serial.startIfNeeded()
    }
    
    public func send(_ data: Data, for characteristic: Characteristic) {
        
        serial.addOperation { [weak self] in
            self?.send(data: data, for: characteristic)
        }
        
        serial.startIfNeeded()
    }
    
    private func send(data: Data, for characteristic: Characteristic) {
        
        guard let char = serviceControllers.compactMap(\.service.characteristics).reduce([], +).first(where: {
            $0.uuid == characteristic.char.uuid
        }) as? CBMutableCharacteristic else { return }
        
        peripheral.updateValue(data, for: char, onSubscribedCentrals: centrals)
    }
    
    public func receive(_ handler: @escaping DataHandler) {
        
        self.handler = handler
    }
}


// MARK: - CBPeripheralManagerDelegate

extension Host: CBPeripheralManagerDelegate {
    
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
        let serviceUUID = request.characteristic.service.uuid
        serviceControllers
            .first(where: { $0.service.uuid == serviceUUID })
            .map { $0.handleReadRequest(request, peripheral: peripheral) }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        peripheral.respond(to: requests.first!, withResult: .success)
        
        let str = requests.first?.value?.string ?? ""
        if str.contains("Size: ") == true {
            dataHelper = BigDataHelper(with: { (result) in
                self.handler?(result.data(using: .utf8)!, self.charType.from(requests.first!.characteristic.uuid.uuidString))
                self.dataHelper = nil
            })
        } else {
            if dataHelper == nil {
                handler?(requests.first!.value,
                         charType.from(requests.first!.characteristic.uuid.uuidString))
            }
        }
        
        dataHelper?.receive(requests.first!.value!)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("\(#function)")
        if !centrals.contains(central) {
            centrals.append(central)
        }
    }
}
