//
//  Client.swift
//  BTMessaging
//
//  Created by Dima Virych on 19.06.2020.
//  Copyright © 2020 Virych. All rights reserved.
//

import CoreBluetooth

public protocol BTMClientDelegate: class {
    
    func client(_ client: BTMClient, didFoundDevices devices: [BTMDevice])
    func client(_ client: BTMClient, didConnectToDevice device: BTMDevice)
    func client(_ client: BTMClient, didReceiveData data: Data, for characteristic: Characteristic)
    func client(_ client: BTMClient, didDisconnectFromDevice device: BTMDevice)
}

public final class BTMClient: NSObject {
    
    // MARK: - Private Properties
    
    private let serial = SerialQueue()
    private let queue = DispatchQueue.global(qos: .utility)
    
    private var manager: CBCentralManager!
    private var peripherals: [(CBPeripheral, String)] = []
    private var connectedPeripheral: CBPeripheral?
    private var characteristics: [CBCharacteristic] = []
    private var charType: Characteristic.Type
    private var service: CBUUID
    private var dataHelper: BigDataHelper?
    private var devices: [(String, String, Int)] = []
    
    
    // MARK: - Public Properties
    
    public weak var delegate: BTMClientDelegate?
    
    
    // MARK: - Lifecycle
    
    public init(for service: CBUUID = CBUUID(string: "0x101D"), type: Characteristic.Type) {
        self.charType = type
        self.service = service
        super.init()
    }
    
    // MARK: - Action
    
    public func startScanning() {
        devices.removeAll()
        peripherals.removeAll()
        manager = CBCentralManager(delegate: self, queue: queue)
        manager.scanForPeripherals(withServices: [service], options: nil)
    }
    
    public func connect(_ peripheral: String) {
        
        characteristics.removeAll()
        if let ph = peripherals.first(where: { $0.1 == peripheral })?.0 {
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

extension BTMClient: BTMessaging {
    
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
        
        guard let char = characteristics.first(where: { $0.uuid == characteristic.char.uuid }) else {
            return
        }
        
        connectedPeripheral?.writeValue(data, for: char, type: .withResponse)
    }
}


// MARK: - CBPeripheralDelegate

extension BTMClient: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        peripheral.services?
            .forEach { peripheral.discoverCharacteristics($0.characteristics?.map { $0.uuid }, for: $0) }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        let str = characteristic.value?.string ?? ""
        if str.contains("Size: ") == true {
            dataHelper = BigDataHelper(with: { [weak self] (result) in
                
                guard let self = self, let data = result.data(using: .utf8) else { return }
                main {
                    if let char = self.charType.from(characteristic.uuid.uuidString) {
                    self.delegate?.client(self,
                                          didReceiveData: data,
                                          for: char)
                    }
                }
                self.dataHelper = nil
            })
        } else {
            if dataHelper == nil, let data = characteristic.value {
                main {
                    if let char = self.charType.from(characteristic.uuid.uuidString) {
                    self.delegate?.client(self,
                                          didReceiveData: data,
                                          for: char)
                    }
                }
            }
        }
        
        dataHelper?.receive(characteristic.value!)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        characteristics.append(contentsOf: service.characteristics ?? [])
        characteristics.forEach { peripheral.setNotifyValue(true, for: $0) }
    }
}


// MARK: - CBCentralManagerDelegate

extension BTMClient: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [service], options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var tName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        if tName == nil {
            tName = ((advertisementData[CBAdvertisementDataServiceDataKey] as? [AnyHashable : Any])?.first?.value as? Data)?.string
        }
        guard let name = tName else {
            return
        }
        
        if devices.first(where: { $0.0 == name }) == nil {
            
            peripherals.append((peripheral, name))
            devices.append((name, peripheral.identifier.uuidString, RSSI.intValue))
            main {
                self.delegate?.client(self, didFoundDevices: self.devices.map { BTMDevice(from: $0) })
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        peripheral.discoverServices(nil)
        if let device = devices.first(where: { $0.1 == peripheral.identifier.uuidString }) {
            main {
                self.delegate?.client(self, didConnectToDevice: BTMDevice(from: device))
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if let device = devices.first(where: { $0.1 == peripheral.identifier.uuidString }) {
            main {
                self.delegate?.client(self, didDisconnectFromDevice: BTMDevice(from: device))
            }
        }
    }
}
