
# Welcome to BTMessaging

### Swift Package Manager

  

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but Alamofire does support its use on supported platforms.

  

Once you have your Swift package set up, adding Alamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

  

```swift

dependencies: [
    .package(url: "https://github.com/damienissa/BTMessaging.git")
]

```

### Characteristic
First of all we need create Characteristic
```swift

enum  Char: Characteristic {
    
    case demo
    
    var  char: CBMutableCharacteristic {
	CBMutableCharacteristic(type: CBUUID(string: "0x3232"), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
    }
    
    static func from(_ string: String?) -> Char {
	.demo
    }
}
 ```
### Host
How to create host: 
```swift

    let host = BTMHost(service: CBUUID(string: "0xFFDD"), peripheralName: "My Host Name", type: Char.self)
    host.delegate = self
    try? host.turnOn()
```

### Receive ivents from BTMHost using BTMHostDelegate
```swift
    
    func host(_ host: BTMHost, didReceiveConnectionFrom central: CBCentral) {
    	// here you will get new connected *central*
    }
    
    func host(_ host: BTMHost, didReceiveDisconnectionFrom central: CBCentral) {
	// here you will receive disconnection from *central*
    }
    
    func host(_ host: BTMHost, didReceiveData data: Data, for characteristic: Characteristic) {
    	// here you will receive new data for *characteristic*
    }
```

### Client
How to create host: 
```swift
   
    let client = BTMClient(for: CBUUID(string: "0xFFDD"), type: Char.self)
    client.delegate = self
    client.connect("Host name HERE")
```

### Receive ivents from BTMClient using BTMClientDelegate
```swift

    func client(_ client: BTMClient, didFoundDevices devices: [BTMDevice]) {
   	// here you will receive dounded devices
    }
    
    func client(_ client: BTMClient, didConnectToDevice device: BTMDevice) {
   	// here you will receive connected device
    }
    
    func client(_ client: BTMClient, didReceiveData data: Data, for characteristic: Characteristic) {
   	// here you will receive data from connected host
    }
    
    func client(_ client: BTMClient, didDisconnectFromDevice device: BTMDevice) {
   	// here you will receive disconnection from device
    }
```

### Sending Data on both Client and Host
```swift

    let hData = "Some Data for host"
    let cData = "Some Data for client"
    client.send(hData, for: Char.demo)
    host.send(cData, for: Char.demo)
 ```   
### Sending big data
First of all you must convert your data to the string! You can use `Codable` or any other way to convert data!  Next step is use chunk helper `chunkedData(with: SIZE_OF_CHUNK)`
Default chunk size for big data is 128 symbols but you can change it using: `BTMessagingSettings.chunkSize = 30`
Example:
```swift

    let dat = Array(0..<100).compactMap(String.init).joined(separator: ", ")
    host.send(dat, for: Char.demo)
```
The same way you can send data from the client:
```swift
    let dat = Array(100..<200).compactMap(String.init).joined(separator: ", ")
    client.send(dat, for: Char.demo)
```
### Welcome!
