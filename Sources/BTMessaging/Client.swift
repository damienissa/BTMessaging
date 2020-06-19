//
//  Client.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import CoreBluetooth

public final class Client: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Properties
    
    private let queue = DispatchQueue.global(qos: .utility)
    private var manager: CBCentralManager!
    private var peripherals: [CBPeripheral] = [] {
        didSet {
            didFoundDevices?(peripherals.compactMap(\.name), self)
        }
    }
    private var connectedPeripheral: CBPeripheral?
    private var didFoundDevices: (([String], Client) -> Void)?
    private var characteristics: [CBCharacteristic] = []
    private var handler: BTMessanging.DataHandler?
    private var charType: Characteristic.Type
    
    // MARK: - Lifecycle
    
    public init(type: Characteristic.Type, _ completion: (([String], Client) -> Void)? = nil) {
        self.charType = type
        super.init()

        didFoundDevices = completion
        manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        print(central.state)
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [CBUUID(string: "0x101D")], options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        print(peripheral)
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
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
        
        handler?(characteristic.value,
        charType.from(characteristic.uuid.uuidString))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        characteristics.append(contentsOf: service.characteristics ?? [])
        characteristics.forEach { peripheral.setNotifyValue(true, for: $0) }
    }
    
    // MARK: - Action
    
    public func connect(_ peripheral: String) {
        if let ph = peripherals.first(where: {
            $0.name == peripheral
        }) {
            manager.stopScan()
            manager.connect(ph, options: nil)
        }
    }
}

extension Client: BTMessanging {
    
    public func send(_ data: Data, for characteristic: Characteristic) {
        
        // MARK: - Data limit - 512 bytes -
        if let char = characteristics.first(where: { $0.uuid == characteristic.char.uuid }) {
            print(char)
            connectedPeripheral?.writeValue(data, for: char, type: .withoutResponse)
        }
    }
    
    public func receive(_ handler: @escaping DataHandler) {
        
        self.handler = handler
    }
}

