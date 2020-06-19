//
//  Client.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import CoreBluetooth

public struct Device {
    
    public let name: String
    public let advertisementData: [String : Any]
    public let rssi: Int
    
    init(from data: (CBPeripheral, [String : Any], Int)) {
        self.name = data.0.name ?? "Unknown"
        self.advertisementData = data.1
        self.rssi = data.2
    }
}

public final class Client: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Properties
    
    private let serial = SerialQueue()
    private let queue = DispatchQueue.global(qos: .utility)
    private var manager: CBCentralManager!
    private var peripherals: [(CBPeripheral, [String : Any], Int)] = [] {
        didSet {
            didFoundDevices?(peripherals.map { Device(from: $0) }, self)
        }
    }
    private var connectedPeripheral: CBPeripheral?
    private var characteristics: [CBCharacteristic] = []
    private var handler: BTMessaging.DataHandler?
    private var charType: Characteristic.Type
    private var didFoundDevices: (([Device], Client) -> Void)?
    private var service: CBUUID
    private var dataHelper: BigDataHelper?
    
    
    // MARK: - Lifecycle
    
    public init(for service: CBUUID = CBUUID(string: "0x101D"), type: Characteristic.Type, _ completion: (([Device], Client) -> Void)? = nil) {
        self.charType = type
        self.service = service
        super.init()
        
        didFoundDevices = completion
        manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        print(central.state)
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [service], options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print(peripheral)
        if peripherals.first(where: { $0.1[CBAdvertisementDataLocalNameKey] as? String == advertisementData[CBAdvertisementDataLocalNameKey] as? String }) == nil {
            peripherals.append((peripheral, advertisementData, RSSI.intValue))
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        peripheral.discoverServices(nil)
    }
    
    
    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        peripheral.services?
            .forEach { peripheral.discoverCharacteristics($0.characteristics?.map { $0.uuid }, for: $0) }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        let str = characteristic.value?.string ?? ""
        if str.contains("Size: ") == true {
            dataHelper = BigDataHelper(with: { (result) in
                self.handler?(result.data(using: .utf8)!, self.charType.from(characteristic.uuid.uuidString))
                self.dataHelper = nil
            })
        } else {
            if dataHelper == nil {
                handler?(characteristic.value,
                         charType.from(characteristic.uuid.uuidString))
            }
        }
        
        dataHelper?.receive(characteristic.value!)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        characteristics.append(contentsOf: service.characteristics ?? [])
        characteristics.forEach { peripheral.setNotifyValue(true, for: $0) }
    }
    
    // MARK: - Action
    
    public func connect(_ peripheral: String) {
        
        if let ph = peripherals.first(where: {
            $0.0.name == peripheral || $0.1[CBAdvertisementDataLocalNameKey] as? String == peripheral
            })?.0 {
            manager.stopScan()
            manager.connect(ph, options: nil)
        }
    }
    
    public func disconnect() {
        
        if let per = connectedPeripheral {
            manager.cancelPeripheralConnection(per)
            manager.scanForPeripherals(withServices: [service], options: nil)
        }
    }
}


// MARK: - BTMessaging

extension Client: BTMessaging {
    
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
        
        guard let char = characteristics.first(where: { $0.uuid == characteristic.char.uuid }) else {
            return
        }
        
        connectedPeripheral?.writeValue(data, for: char, type: .withResponse)
    }
    
    public func receive(_ handler: @escaping DataHandler) {
        
        self.handler = handler
    }
}

