
# Welcome to BTMessaging

### Characteristic
First of all we need create Characteristic

        enum  Char: Characteristic {
    
            case demo
    
            var  char: CBMutableCharacteristic {
                CBMutableCharacteristic(type: CBUUID(string: "0x3232"), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
            }
    
            static func from(_ string: String?) -> Char {
                    .demo
            }
        }

### Host
How to create host: 

        
        let host = Host(service: CBUUID(string: "0xFFDD"), peripheralName: "My Host Name", type: Char.self)
        try? host.turnOn()
        
### Receive Data on Host

        host.receive { (data, char) in
            if let d = data, let str = String(data: d, encoding: .utf8) {
                print(str, char)
            }
        }
     
### Client
How to create host: 

        
        let host = Client(for: CBUUID(string: "0xFFDD"), type: Char.self, { (list, _) in 
            // MARK: - List of founded HOSTs
            print(list)
        }
        client.connect("Host name HERE")
   
### Receive Data on Client

        client.receive { (data, char) in
            if let d = data, let str = String(data: d, encoding: .utf8) {
                print(str, char)
            }
        }


### Sending Data on both Client and Host

    let hData = "Some Data for host".data(using: .utf8)!
    let cData = "Some Data for client".data(using: .utf8)!
    client.send(hData, for: Char.demo)
    host.send(cData, for: Char.demo)
    
### Sending big data
**First of all you must convert your data to the string!** You can use `Codable` or any other way to convert data!  Next step is use chunk helper `chunkedData(with: SIZE_OF_CHUNK)`
Example:

	    let dat = Array(0..<100).compactMap(String.init).joined(separator: ", ").chunkedData(with: 128)
	    host.send(dat, for: Char.demo)
The same way you can send data from the client:

	    let dat = Array(0..<100).compactMap(String.init).joined(separator: ", ").chunkedData(with: 128)
        host.send(dat, for: Char.demo)

### Welcome!
